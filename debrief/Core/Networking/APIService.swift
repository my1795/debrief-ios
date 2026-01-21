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
    case quotaExceeded(reason: QuotaExceededReason)
    case validationError(message: String)
}

enum QuotaExceededReason: String, Codable {
    case weeklyDebriefLimit = "WEEKLY_DEBRIEF_LIMIT"
    case weeklyMinutesLimit = "WEEKLY_MINUTES_LIMIT"
    case storageLimit = "STORAGE_LIMIT"
    case durationTooLong = "DURATION_TOO_LONG"
    case fileTooLarge = "FILE_TOO_LARGE"
    case unknown = "UNKNOWN"

    var userMessage: String {
        switch self {
        case .weeklyDebriefLimit:
            return "Weekly debrief limit reached. Upgrade your plan or wait until your billing week resets."
        case .weeklyMinutesLimit:
            return "Weekly recording time limit reached. Upgrade your plan for more minutes."
        case .storageLimit:
            return "Storage limit reached. Delete old debriefs or upgrade your plan."
        case .durationTooLong:
            return "Recording is too long. Maximum duration is 10 minutes."
        case .fileTooLarge:
            return "Audio file is too large. Maximum size is 100MB."
        case .unknown:
            return "Unable to create debrief. Please try again later."
        }
    }
}

/// Backend error response structure
struct APIErrorResponse: Decodable {
    let error: APIErrorDetail?
    let code: String?
    let message: String?
}

struct APIErrorDetail: Decodable {
    let code: String
    let message: String
}

class APIService {
    static let shared = APIService()
    // Base URL is now managed by AppConfig
    private var baseURL: String { AppConfig.shared.apiBaseURL }
    
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
        return responses.map { Contact(id: $0.contactId, name: $0.name, handle: $0.handle ?? "", totalDebriefs: 0, phoneNumbers: [], emailAddresses: []) }
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
        return Contact(id: resp.contactId, name: resp.name, handle: resp.handle ?? "", totalDebriefs: 0, phoneNumbers: [], emailAddresses: [])
    }
    
    // MARK: - Search
    
    private struct EmbeddingRequest: Encodable {
        let text: String
    }
    
    private struct EmbeddingResponse: Decodable {
        let embedding: [Double]
    }
    
    func generateEmbedding(text: String) async throws -> [Double] {
        let isVerbose = AppConfig.shared.isVerboseLoggingEnabled
        
        guard let url = URL(string: "\(baseURL)/debriefs/embedding") else {
            throw APIError.invalidURL
        }
        
        if isVerbose {
            print("🌐 [APIService.generateEmbedding] ========== REQUEST ==========")
            print("🌐 [APIService.generateEmbedding] URL: \(url.absoluteString)")
            print("🌐 [APIService.generateEmbedding] Text length: \(text.count) chars")
            print("🌐 [APIService.generateEmbedding] Text preview: \"\(String(text.prefix(50)))...\"")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization Header for current user
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if isVerbose {
                print("🌐 [APIService.generateEmbedding] Auth token: \(String(token.prefix(20)))...")
            }
        }
        
        let body = EmbeddingRequest(text: text)
        let bodyDict = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        
        if isVerbose {
            print("🌐 [APIService.generateEmbedding] ========== REQUEST BODY ==========")
            print("🌐 [APIService.generateEmbedding] Full query text: \"\(text)\"")
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("🌐 [APIService.generateEmbedding] JSON sent: \(jsonString)")
            }
            print("🌐 [APIService.generateEmbedding] Sending request...")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.invalidResponse
        }
        
        if isVerbose {
            print("🌐 [APIService.generateEmbedding] ========== RESPONSE ==========")
            print("🌐 [APIService.generateEmbedding] Status code: \(httpResponse.statusCode)")
            print("🌐 [APIService.generateEmbedding] Response size: \(data.count) bytes")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if isVerbose {
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("❌ [APIService.generateEmbedding] Error body: \(responseBody)")
                }
            }
             throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let resp = try decoder.decode(EmbeddingResponse.self, from: data)
        
        if isVerbose {
            print("✅ [APIService.generateEmbedding] Success! Embedding dimensions: \(resp.embedding.count)")
        }
        
        return resp.embedding
    }

    // MARK: - Semantic Search (Backend)
    
    struct SearchResult: Decodable {
        let debriefId: String
        let similarity: Double
        
        // Backend sends snake_case: debrief_id
        enum CodingKeys: String, CodingKey {
            case debriefId = "debrief_id"
            case similarity
        }
    }
    
    private struct SearchRequest: Encodable {
        let query: String
        let limit: Int
    }
    
    func searchDebriefs(query: String, limit: Int = 10) async throws -> [SearchResult] {
        let isVerbose = AppConfig.shared.isVerboseLoggingEnabled
        
        guard let url = URL(string: "\(baseURL)/debriefs/search") else {
            throw APIError.invalidURL
        }
        
        if isVerbose {
            print("🔍 [APIService.searchDebriefs] ========== REQUEST ==========")
            print("🔍 [APIService.searchDebriefs] URL: \(url.absoluteString)")
            print("🔍 [APIService.searchDebriefs] Query: \"\(query)\"")
            print("🔍 [APIService.searchDebriefs] Limit: \(limit)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization Header
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(SearchRequest(query: query, limit: limit))
        
        if isVerbose {
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("🔍 [APIService.searchDebriefs] JSON sent: \(jsonString)")
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if isVerbose {
            print("🔍 [APIService.searchDebriefs] ========== RESPONSE ==========")
            print("🔍 [APIService.searchDebriefs] Status code: \(httpResponse.statusCode)")
            print("🔍 [APIService.searchDebriefs] Response size: \(data.count) bytes")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if isVerbose {
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("❌ [APIService.searchDebriefs] Error body: \(responseBody)")
                }
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Log raw response for debugging
        if isVerbose {
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("🔍 [APIService.searchDebriefs] Raw JSON: \(rawJSON)")
            }
        }
        
        let decoder = JSONDecoder()
        // Note: Backend uses camelCase (debriefId), no conversion needed
        let results = try decoder.decode([SearchResult].self, from: data)
        
        if isVerbose {
            print("✅ [APIService.searchDebriefs] Success! Results: \(results.count)")
            for (i, result) in results.prefix(5).enumerated() {
                print("   \(i+1). ID: \(result.debriefId), Similarity: \(String(format: "%.3f", result.similarity))")
            }
        }
        
        return results
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

    // Helper to avoid duplication (still used by createDebrief)
    private func mapResponseToDomain(_ resp: DebriefAPIResponse) -> Debrief {
        let mappedStatus: DebriefStatus = {
            switch resp.status {
            case "CREATED": return .created
            case "PROCESSING": return .processing
            case "READY": return .ready
            case "FAILED": return .failed
            default: return .created
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
    
    func createDebrief(audioUrl: URL, contact: Contact, duration: TimeInterval) async throws -> Debrief {
        // Convert to Int seconds for API
        let durationSec = Int(duration)
        guard let url = URL(string: "\(baseURL)/debriefs") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var data = Data()
        
        // --- Add Contact Fields ---
        
        func append(_ value: String, name: String) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 1. Phone Numbers (Priority: use first available)
        if let phone = contact.phoneNumbers.first {
             append(normalizePhoneNumber(phone), name: "phoneNumber")
        }
        
        // 2. Email (Priority: use first available)
        if let email = contact.emailAddresses.first {
             append(email.lowercased(), name: "email")
        }
        
        // 3. Contact Name (Display)
        append(contact.name, name: "contactName")
        
        // 4. Contact ID (Device ID)
        append(contact.id, name: "contactId")
        
        // Duration
        append("\(durationSec)", name: "durationSec")
        
        // --- Add Audio Data ---
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle error responses
        if ![201, 202].contains(httpResponse.statusCode) {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: responseData) {
                let errorCode = errorResponse.error?.code ?? errorResponse.code ?? ""

                switch errorCode {
                case "QUOTA_EXCEEDED":
                    let reason = QuotaExceededReason(rawValue: errorResponse.error?.message ?? "") ?? .unknown
                    throw APIError.quotaExceeded(reason: reason)
                case "VALIDATION_ERROR":
                    throw APIError.validationError(message: errorResponse.error?.message ?? "Invalid request")
                case "FILE_TOO_LARGE":
                    throw APIError.quotaExceeded(reason: .fileTooLarge)
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let resp = try decoder.decode(DebriefAPIResponse.self, from: responseData)
        return mapResponseToDomain(resp)
    }

    // MARK: - Encryption
    
    /// Exchanges Firebase ID token for user's encryption key.
    /// Call once after login, store key in Keychain.
    /// - Returns: EncryptionKeyResponse containing the base64-encoded key
    /// - Throws: APIError.serverError(503) if encryption is disabled on server
    func exchangeKey() async throws -> EncryptionKeyResponse {
        guard let url = URL(string: "\(baseURL)/auth/exchange-key") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Must have authenticated user
        guard let user = Auth.auth().currentUser else {
            print("❌ [APIService] exchangeKey: No authenticated user")
            throw APIError.invalidResponse
        }
        
        let token = try await user.getIDToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔐 [APIService] POST /auth/exchange-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle 503 (encryption disabled on server)
        if httpResponse.statusCode == 503 {
            print("⚠️ [APIService] Encryption not enabled on server (503)")
            throw APIError.serverError(503)
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(EncryptionKeyResponse.self, from: data)
    }
    
    // MARK: - Stats

    func getStatsOverview() async throws -> OverviewResponse {
        return try await performRequest(endpoint: "/stats/overview", method: "GET")
    }

    // MARK: - Stats Read Strategy
    //
    // READ OPERATIONS: Use Firestore snapshots/listeners directly (no backend API calls)
    // - user_plans collection → FirestoreService.observeUserPlan() for billing/quota
    // - debriefs collection → FirestoreService.getWeeklyStats() for stats aggregation
    //
    // This approach:
    // 1. Reduces backend load
    // 2. Enables real-time updates via Firestore listeners
    // 3. Leverages Firebase's built-in caching
    //
    // WRITE OPERATIONS: Use backend API
    // - POST /v1/debriefs → Creates debrief, backend handles quota check & usage increment
    // - DELETE /v1/debriefs/{id} → Backend handles storage refund
    //
    
    // MARK: - Management
    
    func deleteDebrief(id: String) async throws {
        // According to REST standards, DELETE should return 204 No Content usually.
        // We use performRequest but expect Void/Empty response.

        guard let url = URL(string: "\(baseURL)/debriefs/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // CRITICAL: Add Authorization header
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
    }
    
    // MARK: - Free Voice Storage

    struct FreeVoiceStorageResponse: Decodable {
        let success: Bool?
        let message: String?
        // Optional fields - backend may process async and not return these
        let freedAt: String?
        let deletedFilesCount: Int?
        let updatedDebriefsCount: Int?
        let freedStorageMB: Int?
    }

    /// Deletes all audio files from storage while preserving transcripts, summaries, and action items
    /// Backend returns 202 Accepted and processes in background
    func freeVoiceStorage() async throws -> FreeVoiceStorageResponse {
        guard let url = URL(string: "\(baseURL)/account/audio") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }

        // Handle empty response (202 Accepted with no body)
        if data.isEmpty {
            return FreeVoiceStorageResponse(
                success: true,
                message: "Request accepted, processing in background",
                freedAt: nil,
                deletedFilesCount: nil,
                updatedDebriefsCount: nil,
                freedStorageMB: nil
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FreeVoiceStorageResponse.self, from: data)
    }
    
    // MARK: - Account Management
    
    struct DeleteAccountResponse: Decodable {
        let success: Bool
        let message: String
        let deletedAt: Date?
    }
    
    func deleteAccount() async throws -> DeleteAccountResponse {
        guard let url = URL(string: "\(baseURL)/account") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DeleteAccountResponse.self, from: data)
    }
    
    // MARK: - Helpers
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        // Remove all non-digit characters except leading +
        var normalized = phone.filter { $0.isNumber || $0 == "+" }

        // Ensure country code (default to +1 for US if missing)
        if !normalized.hasPrefix("+") {
            if normalized.count == 10 {
                normalized = "+1" + normalized  // US number
            } else {
                normalized = "+" + normalized
            }
        }

        return normalized
    }
    
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
