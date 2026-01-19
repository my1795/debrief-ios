import Foundation
import AVFoundation
import Combine

class AudioPlaybackService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var decryptionError: Error?
    @Published var playbackRate: Float = 1.0  // 1.0, 1.5, 2.0
    
    // Remote Player (Streaming)
    private var avPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    // Local Data Player (Decrypted)
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    // State Tracking
    private var currentEncryptedURL: URL? // To track "toggle" for encrypted
    private var cachedDecryptedData: Data? // Cache decrypted data to avoid re-download/re-decrypt on toggle
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ [AudioPlayback] Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Public API
    
    /// Plays unencrypted audio from a remote URL (Streaming)
    @MainActor
    func play(url: URL) {
        stop() // Reset
        setupAudioSession()
        
        let playerItem = AVPlayerItem(url: url)
        avPlayer = AVPlayer(playerItem: playerItem)
        
        isLoading = true
        
        // Status Observer
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                if item.status == .readyToPlay {
                    self?.isLoading = false
                    self?.avPlayer?.play()
                    self?.isPlaying = true
                } else if item.status == .failed {
                    self?.isLoading = false
                    print("❌ [AudioPlayback] AVPlayer failed: \(item.error?.localizedDescription ?? "Unknown")")
                }
            }
        }
        
        // Duration
        Task {
            if let d = try? await playerItem.asset.load(.duration) {
                self.duration = CMTimeGetSeconds(d)
            }
        }
        
        // Time Observer
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
        
        // Completion
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    /// Downloads, decrypts, and plays encrypted audio using AVAudioPlayer (Memory-based)
    @MainActor
    func playEncryptedAudio(from remoteURL: URL, using key: Data) async {
        stop() // Reset
        setupAudioSession()
        
        isLoading = true
        decryptionError = nil
        currentEncryptedURL = remoteURL
        
        do {
            // 1. Download info
            print("🎵 [AudioPlayback] Downloading encrypted audio...")
            let (encryptedData, _) = try await URLSession.shared.data(from: remoteURL)
            print("🎵 [AudioPlayback] Downloaded \(encryptedData.count) bytes")
            
            // 2. Decrypt (Memory)
            print("🎵 [AudioPlayback] Decrypting...")
            let decryptedData = try EncryptionService.shared.decryptAudioData(encryptedData, using: key)
            print("🎵 [AudioPlayback] Decrypted \(decryptedData.count) bytes. Initializing player...")
            
            // Cache for toggle
            self.cachedDecryptedData = decryptedData
            
            // 3. Init AVAudioPlayer
            try playDecryptedData(decryptedData)
            
        } catch {
            print("❌ [AudioPlayback] Encrypted playback failed: \(error)")
            decryptionError = error
            isLoading = false
        }
    }
    
    /// Toggle play/pause for encrypted audio
    @MainActor
    func toggleEncrypted(remoteURL: URL, key: Data) async {
        // If we have cached data for this URL, reuse it
        if let currentUrl = currentEncryptedURL, currentUrl == remoteURL, let data = cachedDecryptedData {
            if isPlaying {
                pause()
            } else {
                // Resume or restart?
                if audioPlayer != nil {
                    audioPlayer?.play()
                    startTimer()
                    isPlaying = true
                } else {
                    // Player was stopped/nil, re-init with data
                    try? playDecryptedData(data)
                }
            }
            return
        }
        
        // New track or nothing cached
        await playEncryptedAudio(from: remoteURL, using: key)
    }
    
    // MARK: - Generic Controls
    
    @MainActor
    func toggle(url: URL) {
        // If playing unencrypted AVPlayer
        if let currentItem = avPlayer?.currentItem, (currentItem.asset as? AVURLAsset)?.url == url {
            if isPlaying { pause() } else { avPlayer?.play(); isPlaying = true }
            return
        }
        
        // Start new
        play(url: url)
    }
    
    @MainActor
    func pause() {
        avPlayer?.pause()
        audioPlayer?.pause()
        timer?.invalidate()
        isPlaying = false
    }
    
    @MainActor
    func stop() {
        // Stop Streaming
        avPlayer?.pause()
        avPlayer = nil
        statusObserver?.invalidate()
        statusObserver = nil
        if let obs = timeObserver { avPlayer?.removeTimeObserver(obs) }
        timeObserver = nil
        
        // Stop Local
        audioPlayer?.stop()
        audioPlayer = nil
        timer?.invalidate()
        timer = nil
        
        // Reset State
        isPlaying = false
        isLoading = false
        currentTime = 0
        // Don't clear cachedDecryptedData here immediately to allow resume?
        // Actually stop() usually means full stop. Clearing cache is safer for memory.
        // But for "Toggle" logic, we might want pause() instead.
        // User asked for stop() -> full reset.
        cachedDecryptedData = nil
        currentEncryptedURL = nil
    }
    
    @MainActor
    func seek(to time: TimeInterval) {
        if let player = avPlayer {
            player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        } else if let player = audioPlayer {
            player.currentTime = time
        }
        currentTime = time
    }
    
    @MainActor
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        
        if let player = avPlayer {
            player.rate = rate
        } else if let player = audioPlayer {
            player.rate = rate
        }
    }

    // MARK: - Private Helpers (AVAudioPlayer)
    
    @MainActor
    private func playDecryptedData(_ data: Data) throws {
        // Initialize player with DATA
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.enableRate = true  // Enable playback speed adjustment
        audioPlayer?.prepareToPlay()
        audioPlayer?.rate = playbackRate  // Apply current rate
        duration = audioPlayer?.duration ?? 0
        
        print("🎵 [AudioPlayback] AVAudioPlayer ready. Duration: \(duration)")
        
        audioPlayer?.play()
        isPlaying = true
        isLoading = false
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTime()
            }
        }
    }
    
    @MainActor
    private func updateTime() {
        if let p = audioPlayer {
            currentTime = p.currentTime
        }
    }
    
    // MARK: - Delegates
    
    @MainActor
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0
        audioPlayer?.currentTime = 0
        avPlayer?.seek(to: .zero)
        timer?.invalidate()
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            playerDidFinishPlaying()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [AudioPlayback] AVAudioPlayer decode error: \(error?.localizedDescription ?? "nil")")
        Task { @MainActor in
            self.isLoading = false
            self.isPlaying = false
        }
    }
}
