//
//  EducationContent.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 25/01/2026.
//

import Foundation

struct EducationPage: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
}

struct EducationTopic: Identifiable {
    let id: String
    let title: String
    let pages: [EducationPage]
}

enum EducationTopics {

    // MARK: - Record Screen
    static let record = EducationTopic(
        id: "record",
        title: "How Recording Works",
        pages: [
            EducationPage(
                emoji: "🎙️",
                title: "Record Your Thoughts",
                description: "After a call, tap record and speak freely. Share what happened, decisions made, and next steps."
            ),
            EducationPage(
                emoji: "🔒",
                title: "100% Private",
                description: "Your debriefs are only for you. Nothing is ever sent to your contacts or shared with anyone else. All data stays encrypted on your device."
            ),
            EducationPage(
                emoji: "✨",
                title: "AI-Powered Summaries",
                description: "We transcribe and organize your debrief into key points, action items, and insights."
            ),
            EducationPage(
                emoji: "👤",
                title: "Link to Contacts",
                description: "Associate debriefs with people to organize your notes. This is just for you — nothing is ever sent or shared with your contacts."
            )
        ]
    )

    // MARK: - Timeline Screen
    static let timeline = EducationTopic(
        id: "timeline",
        title: "Your Debriefs",
        pages: [
            EducationPage(
                emoji: "📋",
                title: "Your Debrief Timeline",
                description: "All your debriefs in one place, organized by date. Tap any card to see full details."
            ),
            EducationPage(
                emoji: "✨",
                title: "AI-Powered Search",
                description: "Search by meaning, not just keywords. Type \"money\" to find debriefs about budget, pricing, or finances."
            ),
            EducationPage(
                emoji: "🎯",
                title: "Smart Filters",
                description: "Filter by contact, date range, or tags to quickly find what you need."
            ),
            EducationPage(
                emoji: "📊",
                title: "Daily Stats",
                description: "The pill at the top shows your activity: debriefs recorded and minutes captured today."
            )
        ]
    )

    // MARK: - Contacts Screen
    static let contacts = EducationTopic(
        id: "contacts",
        title: "People You Talk To",
        pages: [
            EducationPage(
                emoji: "👥",
                title: "People You Talk To",
                description: "Every person you link to a debrief appears here. Build context for your relationships."
            ),
            EducationPage(
                emoji: "📈",
                title: "Contact Insights",
                description: "See how often you talk, key topics discussed, and pending action items per person."
            ),
            EducationPage(
                emoji: "🔗",
                title: "Auto-Suggestions",
                description: "When you record, we suggest contacts based on names mentioned in your debrief."
            )
        ]
    )

    // MARK: - Stats Screen
    static let stats = EducationTopic(
        id: "stats",
        title: "Your Activity",
        pages: [
            EducationPage(
                emoji: "📊",
                title: "Your Activity Stats",
                description: "Track debriefs created, minutes recorded, and action items generated each week."
            ),
            EducationPage(
                emoji: "📅",
                title: "Billing Week",
                description: "Your usage resets every Sunday. Check your quota and plan limits here."
            ),
            EducationPage(
                emoji: "🏆",
                title: "Top Contacts",
                description: "See who you communicate with most based on debrief frequency."
            )
        ]
    )
}
