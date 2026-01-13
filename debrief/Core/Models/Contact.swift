//
//  Contact.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation

struct Contact: Identifiable, Codable {
    let id: String
    let name: String
    let handle: String?
    let totalDebriefs: Int
    
    // For mock data convenience
    var contactId: String { id }
}
