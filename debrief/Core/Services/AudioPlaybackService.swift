import Foundation
import AVFoundation
import Combine

class AudioPlaybackService: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
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
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe duration
        Task { @MainActor in
            if let duration = try? await playerItem.asset.load(.duration) {
                self.duration = CMTimeGetSeconds(duration)
            }
        }
        
        player?.play()
        isPlaying = true
        
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
        currentTime = 0
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
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
