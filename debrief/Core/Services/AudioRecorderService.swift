//
//  AudioRecorderService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import AVFoundation

protocol AudioRecorderServiceProtocol {
    func requestPermission() async -> Bool
    func startRecording() async throws
    func stopRecording() -> URL?
    func cleanup(url: URL)
    var currentTime: TimeInterval { get }
}

class AudioRecorderService: NSObject, AudioRecorderServiceProtocol, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording() async throws {
        // Perform session setup off-main-thread
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
        
        // This is safe to run on background but Recorder init must happen.
        // We are in async context so this is better.
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else { return nil }
        
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        
        return url
    }
    
    var currentTime: TimeInterval {
        audioRecorder?.currentTime ?? 0
    }
    
    func cleanup(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
