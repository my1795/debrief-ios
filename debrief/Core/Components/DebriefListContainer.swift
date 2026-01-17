import SwiftUI

struct DebriefListContainer: View {
    // We accept sections to support sticky headers. 
    // If a view only has a flat list, it should pass a single section.
    let sections: [TimelineViewModel.TimelineSection]
    let userId: String
    let isLoading: Bool
    
    // Actions
    let onRefresh: () async -> Void
    let onLoadMore: (Debrief) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.debriefs) { debrief in
                            NavigationLink(destination: DebriefDetailView(debrief: debrief, userId: userId)) {
                                DebriefItem(debrief: debrief, showContactName: shouldShowContactName(for: debrief))
                                    .onAppear {
                                        onLoadMore(debrief)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        // Only show header if we actually have multiple sections or if explicitly desired
                        // For now, mirroring TimelineView behavior: always show if sections exist
                        if !section.title.isEmpty {
                            Text(section.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(Color(hex: "022c22").opacity(0.95))
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding()
                }
                
                // Bottom padding
                Color.clear.frame(height: 80)
            }
            .padding(.top)
        }
        .refreshable {
            await onRefresh()
        }
    }
    
    // Helper to determine if we show name. 
    // Ideally this logic belongs to the parent/caller, but passing a closure for `itemContent` makes this container complex generic.
    // Making it simple for now: If we are in a Contact Detail view, the caller typically filters by contact. 
    // But this container is valid for ALL debriefs too.
    // Solution: Let's assume standard behavior is SHOW name. The parent view can wrap this or we can add a property "showContactNames" to this container.
    // Actually, `DebriefItem` has `showContactName`. 
    // We need to know if we should hide it. 
    // Let's add a property to this container `hideContactNames`.
    
    var hideContactNames: Bool = false
    
    private func shouldShowContactName(for debrief: Debrief) -> Bool {
        if hideContactNames { return false }
        return !debrief.contactName.isEmpty
    }
}
