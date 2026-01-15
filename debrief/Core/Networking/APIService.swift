//
//  APIService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import FirebaseAuth

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
}

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:8080/v1" // Configure in Info.plist later
    
    private init() {}
    
    // MARK: - Contacts
    
    func searchContacts(query: String) async throws -> [Contact] {
        guard let url = URL(string: "\(baseURL)/contacts?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct ContactResponse: Decodable {
            let contactId: String
            let name: String
            let handle: String?
            let handleType: String?
        }
        
        let responses = try decoder.decode([ContactResponse].self, from: data)
        return responses.map { Contact(id: $0.contactId, name: $0.name, handle: $0.handle ?? "", totalDebriefs: 0) }
    }
    
    func createContact(name: String, handle: String) async throws -> Contact {
        guard let url = URL(string: "\(baseURL)/contacts") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "handle": handle,
            "handleType": "GENERIC" // Matching CreateContactRequest DTO
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 201 == httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct ContactResponse: Decodable {
            let contactId: String
            let name: String
            let handle: String?
            let handleType: String?
        }
        
        let resp = try decoder.decode(ContactResponse.self, from: data)
        return Contact(id: resp.contactId, name: resp.name, handle: resp.handle ?? "", totalDebriefs: 0)
    }
    
    // MARK: - Debriefs
    
    // Shared DTO for Response (Internal)
    // Shared DTO for Response (Internal)
    private struct DebriefAPIResponse: Decodable {
        let debriefId: String?
        let contactId: String?
        let occurredAt: Date?
        let audioDurationSec: Int?
        let status: String?
        let summary: String?
        let transcript: String?
        let actionItems: [String]?
        let createdAt: Date?
        let audioUrl: String?
    }
    
    // Deprecated: Uses FirestoreService now
    // func getDebriefs(contactId: String? = nil) async throws -> [Debrief] { ... }
    
    // Deprecated: Uses FirestoreService.getDebrief(userId:debriefId:) now
    // func getDebrief(id: String) async throws -> Debrief { ... }
    
    // Helper to avoid duplication (still used by createDebrief)
    private func mapResponseToDomain(_ resp: DebriefAPIResponse) -> Debrief {
        let mappedStatus: DebriefStatus = {
            switch resp.status {
            case "PROCESSING": return .processing
            case "READY": return .ready
            case "FAILED": return .failed
            default: return .draft
            }
        }()
        
        return Debrief(
            id: resp.debriefId ?? UUID().uuidString,
            userId: Auth.auth().currentUser?.uid ?? "", // Derive from current session
            contactId: resp.contactId ?? "",
            contactName: "", // Name is resolved locally in ViewModel or by caller
            occurredAt: resp.occurredAt ?? Date(),
            duration: TimeInterval(resp.audioDurationSec ?? 0),
            status: mappedStatus,
            summary: resp.summary,
            transcript: resp.transcript,
            actionItems: resp.actionItems,
            audioUrl: resp.audioUrl
        )
    }
    
    func createDebrief(audioUrl: URL, contactId: String) async throws -> Debrief {
        guard let url = URL(string: "\(baseURL)/debriefs?contactId=\(contactId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
             // Handle unauthenticated case, maybe throw error or proceed in some dev mode if applicable
        }
        
        var data = Data()
        
        // Add Audio Data
        if let audioData = try? Data(contentsOf: audioUrl) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 201 == httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let resp = try decoder.decode(DebriefAPIResponse.self, from: responseData)
        return mapResponseToDomain(resp)
    }
    func createDebrief(fileURL: URL, contactId: String?) async throws -> Debrief {
        // ... implementation hidden
        fatalError("Should use the existing implementation") 
    }
    
    // MARK: - Stats
    
    func getStatsOverview() async throws -> OverviewResponse {
        return try await performRequest(endpoint: "/stats/overview", method: "GET")
    }
    
    // MARK: - Management
    
    func deleteDebrief(id: String) async throws {
        // According to REST standards, DELETE should return 204 No Content usually.
        // We use performRequest but expect Void/Empty response.
        
        guard let url = URL(string: "\(baseURL)/debriefs/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
    }
    
    // MARK: - Helpers
    
    func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 [APIService] Added Auth Token (Start): \(token.prefix(10))...")
        } else {
            print("⚠️ [APIService] No User Signed In - Missing Auth Token!")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        print("🚀 [APIService] \(method) \(endpoint)")
        print("   headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
}
