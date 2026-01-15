//
//  StorageService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import Foundation
import FirebaseStorage

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    
    private init() {}
    
    /// Fetches the download URL for a given storage path
    /// - Parameter path: The path in Firebase Storage (e.g., "debriefs/{uid}/{id}/audio.m4a")
    /// - Returns: The public download URL
    func getDownloadURL(for path: String) async throws -> URL {
        let reference = storage.reference(withPath: path)
        return try await reference.downloadURL()
    }
}
