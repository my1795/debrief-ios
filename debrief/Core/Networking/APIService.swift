//
//  APIService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation

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
        
        // Map backend response matching `ContactResponse` schema
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct ContactResponse: Decodable {
            let contactId: String
            let name: String
            let handle: String?
            // Ignoring other fields for now to map to domain model
        }
        
        let responses = try decoder.decode([ContactResponse].self, from: data)
        return responses.map { Contact(id: UUID().uuidString, name: $0.name, handle: $0.handle ?? "", totalDebriefs: 0) } // Adapting to local model
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
            "handleType": "GENERIC" // Defaulting for now
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 201 == httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct ContactResponse: Decodable {
            let contactId: String
            let name: String
            let handle: String?
        }
        
        let resp = try decoder.decode(ContactResponse.self, from: data)
        return Contact(id: resp.contactId, name: resp.name, handle: resp.handle ?? "", totalDebriefs: 0)
    }
    
    // MARK: - Debriefs
    
    func createDebrief(audioUrl: URL, contactId: String) async throws -> Debrief {
        guard let url = URL(string: "\(baseURL)/debriefs?contactId=\(contactId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
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
        
        // Decode logic matching `DebriefResponse`
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct DebriefAPIResponse: Decodable {
            let debriefId: String
            let contactName: String
            let occurredAt: Date
            let audioDurationSec: Int
            let status: String
            let summary: String?
            let transcript: String?
            let actionItems: [String]?
        }
        
        let resp = try decoder.decode(DebriefAPIResponse.self, from: responseData)
        
        // Map status string to Enum
        let mappedStatus: DebriefStatus = {
            switch resp.status {
            case "PROCESSING": return .processing
            case "READY": return .ready
            case "FAILED": return .failed
            default: return .draft
            }
        }()
            
        return Debrief(
            id: resp.debriefId,
            contactName: resp.contactName,
            occurredAt: resp.occurredAt,
            duration: TimeInterval(resp.audioDurationSec),
            status: mappedStatus,
            summary: resp.summary,
            transcript: resp.transcript,
            actionItems: resp.actionItems
        )
    }
}
