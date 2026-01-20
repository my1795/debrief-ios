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

    // Config
    var hideContactNames: Bool = false
    var hasInternalScrollView: Bool = true

    // Internal state for scroll position
    @State private var scrollToTopTrigger = UUID()

    var body: some View {
        if hasInternalScrollView {
            ScrollViewReader { proxy in
                ScrollView {
                    content
                }
                .refreshable {
                    await onRefresh()
                }
                .onChange(of: sections.first?.id) { _ in
                    // Scroll to top when sections change (new data loaded)
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("top_anchor", anchor: .top)
                    }
                }
                .onAppear {
                    // Ensure we start at the top
                    proxy.scrollTo("top_anchor", anchor: .top)
                }
            }
        } else {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
            // Invisible anchor for scrolling to top
            Color.clear
                .frame(height: 1)
                .id("top_anchor")

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
    
    private func shouldShowContactName(for debrief: Debrief) -> Bool {
        if hideContactNames { return false }
        return !debrief.contactName.isEmpty
    }
}
