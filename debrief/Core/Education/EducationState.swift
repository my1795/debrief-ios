//
//  EducationState.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 25/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class EducationState: ObservableObject {
    static let shared = EducationState()

    @AppStorage("seenEducationTopics") private var seenTopicsJSON: String = "[]"

    private var seenTopics: Set<String> {
        get {
            guard let data = seenTopicsJSON.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(array)
        }
        set {
            let array = Array(newValue)
            if let data = try? JSONEncoder().encode(array),
               let json = String(data: data, encoding: .utf8) {
                seenTopicsJSON = json
            }
        }
    }

    func markAsSeen(_ topicId: String) {
        var topics = seenTopics
        topics.insert(topicId)
        seenTopics = topics
        objectWillChange.send()
    }

    func hasSeen(_ topicId: String) -> Bool {
        seenTopics.contains(topicId)
    }

    func resetAll() {
        seenTopics = []
        objectWillChange.send()
    }
}
