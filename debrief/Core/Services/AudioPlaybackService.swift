import Foundation
import AVFoundation
import Combine

class AudioPlaybackService: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    @MainActor
    func play(url: URL) {
        // If already playing this URL, just resume
        if let currentItem = player?.currentItem, 
           let currentUrl = (currentItem.asset as? AVURLAsset)?.url, 
           currentUrl == url {
            player?.play()
            isPlaying = true
            return
        }
        
        // New URL or player not initialized
        stop() // Stop previous
        
        isLoading = true // Start loading
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player item status for buffering
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.player?.play()
                    self?.isPlaying = true
                case .failed:
                    self?.isLoading = false
                    print("❌ [AudioPlayback] Failed to load: \(item.error?.localizedDescription ?? "Unknown")")
                default:
                    break
                }
            }
        }
        
        // Observe duration
        Task { @MainActor in
            if let duration = try? await playerItem.asset.load(.duration) {
                self.duration = CMTimeGetSeconds(duration)
            }
        }
        
        // Observe time
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
        
        // Observe end
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @MainActor
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    @MainActor
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        isLoading = false
        currentTime = 0
        statusObserver?.invalidate()
        statusObserver = nil
        if let observer = timeObserver {
            // Note: player is already nil here, so we can't remove observer
            // But that's fine since player is deallocated
            timeObserver = nil
        }
    }
    
    @MainActor
    func toggle(url: URL) {
        if isPlaying {
            // Check if it's the same URL. If so, pause.
            // If different, play new one.
            if let currentItem = player?.currentItem,
               let currentUrl = (currentItem.asset as? AVURLAsset)?.url,
               currentUrl == url {
                pause()
            } else {
                play(url: url)
            }
        } else {
            play(url: url)
        }
    }
    
    @MainActor
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0
        player?.seek(to: .zero)
    }
}
