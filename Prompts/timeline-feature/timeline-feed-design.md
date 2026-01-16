# Timeline & Feed Design

A comprehensive design document for implementing the debrief timeline view with infinite scroll and search capabilities.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         READS (Timeline, Search)                     │
│                                                                      │
│    iOS App ─────────────────────────────────▶ Firestore             │
│             (Firebase SDK - direct query)                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         WRITES (Create Debrief)                      │
│                                                                      │
│    iOS App ────▶ Backend ────▶ Process ────▶ Firestore              │
│                  (upload,      (transcribe,                          │
│                   validate)     summarize)                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Point:** Mobile reads directly from Firestore - no backend involved for fetching debriefs.

---

## User Intents Analysis

Before picking patterns, understand what users need:

| User Moment | What They Need |
|-------------|----------------|
| "What did John say last week?" | **Search/Filter** by person + time |
| "Let me review my recent calls" | **Timeline** - chronological browse |
| "Before I call Sarah, what did we discuss?" | **Person-centric** lookup |
| "Find that debrief about the contract" | **Semantic search** by content |

Debrief is **person-centric** - that's different from Twitter which is content-centric.

---

## The Core Tension

```
        BROWSE                              FIND
    (Timeline/Feed)                    (Search/Filter)
          │                                   │
          │         ┌─────────────┐           │
          └────────▶│   USER      │◀──────────┘
                    │   INTENT    │
                    └─────────────┘
                          │
                          ▼
                    ┌─────────────┐
                    │  PERSON     │  ← Your core value
                    │  CONTEXT    │
                    └─────────────┘
```

Twitter optimizes for **endless browsing**. But Debrief is a **productivity tool** - users come with intent, not to scroll forever.

---

## Recommended UI Design: Hybrid Approach

```
┌─────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────┐  │
│  │  🔍 Search debriefs...                    │  │  ← Always visible
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ RECENT PEOPLE                        ▶  │   │  ← Horizontal scroll
│  │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │   │
│  │ │John │ │Sarah│ │ Mom │ │Alex │         │   │
│  │ │ 2h  │ │ 1d  │ │ 3d  │ │ 1w  │         │   │
│  │ └─────┘ └─────┘ └─────┘ └─────┘         │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  TIMELINE                                       │
│  ─────────────────────────────────────────────  │
│                                                 │
│  Today                                          │
│  ┌─────────────────────────────────────────┐   │
│  │ 📞 John Smith                    2:34 PM │   │
│  │ Discussed Q4 budget and hiring...       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 📞 Sarah Connor                 11:15 AM │   │
│  │ Contract negotiation follow-up...       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  Yesterday                                      │
│  ┌─────────────────────────────────────────┐   │
│  │ 📞 Mom                           6:22 PM │   │
│  │ Birthday party planning...              │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 📞 John Smith                    3:45 PM │   │
│  │ Initial budget discussion...            │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│             ↓ Loading more...                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Why this works:**
1. **Search always accessible** - One tap away from finding anything
2. **People strip** - Honors person-centric model, quick access
3. **Timeline below** - For browsing/review, infinite scroll
4. **Date grouping** - Mental anchors while scrolling

---

## Filters

### Updated UI with Filter Button

```
┌─────────────────────────────────────────────────┐
│  ┌─────────────────────────────────┐  ┌──────┐ │
│  │  🔍 Search debriefs...          │  │ ⚙️   │ │  ← Filter button
│  └─────────────────────────────────┘  └──────┘ │
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← Active filters (chips)
│  │ ✕ John Smith  ✕ This Week               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ RECENT PEOPLE                        ▶  │   │
│  │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │   │
│  │ │John │ │Sarah│ │ Mom │ │Alex │         │   │
│  │ └─────┘ └─────┘ └─────┘ └─────┘         │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  TIMELINE (3 results)                           │
│  ─────────────────────────────────────────────  │
│  ...                                            │
└─────────────────────────────────────────────────┘
```

### Filter Sheet (Bottom Sheet)

When user taps the filter button:

```
┌─────────────────────────────────────────────────┐
│              FILTERS                        ✕   │
├─────────────────────────────────────────────────┤
│                                                 │
│  CONTACT                                        │
│  ┌─────────────────────────────────────────┐   │
│  │  🔍 Search contacts...                  │   │  ← Searchable!
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │  John Smith                             │   │
│  │  Sarah Connor                           │   │
│  │  Mom                                    │   │
│  │  Alex Johnson                           │   │
│  │  ... (scrollable list)                  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  DATE RANGE                                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Today  │  │  Week   │  │  Month  │        │
│  └─────────┘  └─────────┘  └─────────┘        │
│  ┌─────────┐  ┌─────────────────────────┐     │
│  │   All   │  │  Custom: Jan 1 - Jan 15 │     │
│  └─────────┘  └─────────────────────────┘     │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │            APPLY FILTERS                │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │            CLEAR ALL                    │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Available Filter Fields

| Field | Filter Type | Status |
|-------|-------------|--------|
| `contactId` | Searchable contact picker | ✅ Ready |
| `occurredAt` | Date range picker | ✅ Ready |

### Contact Picker with Search

Since users can have 2000+ contacts, a simple dropdown won't work. Use a **searchable list**:

```
┌─────────────────────────────────────────────────┐
│  CONTACT                                        │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │
│  │  🔍 Search contacts...              |Sa│   │  ← User types "Sa"
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  ○  Sarah Connor                        │   │  ← Filtered results
│  │  ○  Sam Wilson                          │   │
│  │  ○  Sandra Lee                          │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  Selected: None                                 │
└─────────────────────────────────────────────────┘
```

**After selection:**

```
┌─────────────────────────────────────────────────┐
│  CONTACT                                        │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │
│  │  ✓ Sarah Connor                     ✕   │   │  ← Selected (tap ✕ to clear)
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  🔍 Change contact...                   │   │  ← Can search again
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Filter State Model (Swift)

```swift
struct DebriefFilters {
    var contactId: String?
    var contactName: String?  // For display in chips
    var dateRange: DateRange?

    var isActive: Bool {
        contactId != nil || dateRange != nil
    }

    var activeFilterCount: Int {
        [contactId != nil, dateRange != nil].filter { $0 }.count
    }

    mutating func clear() {
        contactId = nil
        contactName = nil
        dateRange = nil
    }
}

enum DateRange: Equatable {
    case today
    case thisWeek
    case thisMonth
    case all
    case custom(start: Date, end: Date)

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .all: return "All Time"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    var startDate: Date? {
        switch self {
        case .today: return Calendar.current.startOfDay(for: Date())
        case .thisWeek: return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .thisMonth: return Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case .all: return nil
        case .custom(let start, _): return start
        }
    }

    var endDate: Date? {
        switch self {
        case .custom(_, let end): return end
        default: return nil
        }
    }
}
```

### Firestore Query with Filters (Swift)

```swift
func buildQuery(filters: DebriefFilters) -> Query {
    var query: Query = Firestore.firestore()
        .collection("debriefs")
        .whereField("userId", isEqualTo: Auth.auth().currentUser!.uid)

    // Filter by contact
    if let contactId = filters.contactId {
        query = query.whereField("contactId", isEqualTo: contactId)
    }

    // Filter by date range (start)
    if let startDate = filters.dateRange?.startDate {
        query = query.whereField("occurredAt", isGreaterThanOrEqualTo: startDate.timeIntervalSince1970 * 1000)
    }

    // Filter by date range (end) - only for custom range
    if let endDate = filters.dateRange?.endDate {
        query = query.whereField("occurredAt", isLessThanOrEqualTo: endDate.timeIntervalSince1970 * 1000)
    }

    return query
        .order(by: "occurredAt", descending: true)
        .limit(to: 20)
}
```

### Searchable Contact Picker Component

```swift
struct SearchableContactPicker: View {
    @Binding var selectedContactId: String?
    @Binding var selectedContactName: String?

    @State private var searchText = ""
    @State private var contacts: [Contact] = []

    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTACT")
                .font(.caption)
                .foregroundColor(.secondary)

            // Show selected contact or search field
            if let name = selectedContactName {
                // Selected state
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(name)
                    Spacer()
                    Button(action: {
                        selectedContactId = nil
                        selectedContactName = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(
                    selectedContactName == nil ? "Search contacts..." : "Change contact...",
                    text: $searchText
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Results list (only show when searching)
            if !searchText.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredContacts.prefix(10)) { contact in
                            Button(action: {
                                selectedContactId = contact.id
                                selectedContactName = contact.name
                                searchText = ""
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(contact.initials)
                                                .font(.caption)
                                        )
                                    Text(contact.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
    }
}
```

### Active Filter Chips Component

```swift
struct ActiveFilterChips: View {
    @Binding var filters: DebriefFilters

    var body: some View {
        if filters.isActive {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Contact chip
                    if let contactName = filters.contactName {
                        FilterChip(label: contactName) {
                            filters.contactId = nil
                            filters.contactName = nil
                        }
                    }

                    // Date range chip
                    if let dateRange = filters.dateRange, dateRange != .all {
                        FilterChip(label: dateRange.displayName) {
                            filters.dateRange = nil
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}
```

---

## Technical Implementation

### Why Cursor Pagination (Not Offset)

```
OFFSET (if it existed):
────────────────────────────────────────────────────────
Page 50 = Skip 1000 documents, then read 20
        = Firestore charges you for 1020 reads 💸

CURSOR:
────────────────────────────────────────────────────────
start(afterDocument: lastDoc) + limit(20)
        = Firestore jumps directly to position
        = Firestore charges you for 20 reads ✓
```

Firestore doesn't even support offset - it forces you to use cursors. This is the correct approach.

### Mobile Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS APP                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    DebriefListViewModel                     │ │
│  │  debriefs: [Debrief]                                       │ │
│  │  lastDocument: DocumentSnapshot?  ← cursor for next page   │ │
│  │  hasMore: Bool                                             │ │
│  └──────────────────────────┬─────────────────────────────────┘ │
│                             │                                    │
│                             ▼                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Firebase SDK (Firestore)                       │ │
│  │  .collection("debriefs")                                   │ │
│  │  .whereField("userId", ==)                                 │ │
│  │  .order(by: "createdAt", descending: true)                 │ │
│  │  .start(afterDocument: cursor)                             │ │
│  │  .limit(to: 20)                                            │ │
│  └──────────────────────────┬─────────────────────────────────┘ │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │    FIRESTORE    │
                    │   /debriefs     │
                    └─────────────────┘
```

### Firestore Queries (Swift)

**First page - no cursor:**
```swift
let query = Firestore.firestore()
    .collection("debriefs")
    .whereField("userId", isEqualTo: userId)
    .order(by: "createdAt", descending: true)
    .limit(to: 20)
```

**Next page - use last document as cursor:**
```swift
let query = Firestore.firestore()
    .collection("debriefs")
    .whereField("userId", isEqualTo: userId)
    .order(by: "createdAt", descending: true)
    .start(afterDocument: lastDocument)  // ← cursor is a DocumentSnapshot
    .limit(to: 20)
```

### Complete ViewModel Implementation

```swift
class DebriefListViewModel: ObservableObject {
    @Published var debriefs: [Debrief] = []
    @Published var isLoading = false

    private var lastDocument: DocumentSnapshot?
    private var hasMore = true

    // MARK: - First Page
    func loadFirstPage() {
        isLoading = true

        Firestore.firestore()
            .collection("debriefs")
            .whereField("userId", isEqualTo: Auth.auth().currentUser!.uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }

                self.debriefs = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Debrief.self)
                }
                self.lastDocument = snapshot.documents.last
                self.hasMore = snapshot.documents.count == 20
                self.isLoading = false
            }
    }

    // MARK: - Next Page (Infinite Scroll)
    func loadNextPage() {
        guard let lastDoc = lastDocument, hasMore, !isLoading else { return }

        isLoading = true

        Firestore.firestore()
            .collection("debriefs")
            .whereField("userId", isEqualTo: Auth.auth().currentUser!.uid)
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }

                let newDebriefs = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Debrief.self)
                }
                self.debriefs.append(contentsOf: newDebriefs)
                self.lastDocument = snapshot.documents.last
                self.hasMore = snapshot.documents.count == 20
                self.isLoading = false
            }
    }

    // MARK: - Trigger Load When Near End
    func loadMoreIfNeeded(currentItem: Debrief) {
        guard let index = debriefs.firstIndex(where: { $0.id == currentItem.id }),
              index >= debriefs.count - 5,
              !isLoading,
              hasMore else { return }

        loadNextPage()
    }
}
```

### SwiftUI View with Infinite Scroll

```swift
struct DebriefListView: View {
    @StateObject private var viewModel = DebriefListViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Search bar
                SearchBar(text: $searchText)

                // People strip (Phase 2)
                // RecentPeopleStrip()

                // Timeline
                ForEach(viewModel.debriefs) { debrief in
                    DebriefCard(debrief: debrief)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: debrief)
                        }
                }

                // Loading indicator
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadFirstPage()
        }
    }
}
```

---

## Search Architecture Options

### Option A: Local Filter (Phase 1)
```
User types → Filter locally on already-loaded items
           → Simple, works for small datasets
```

### Option B: Firestore Prefix Query (Phase 1)
```swift
// Search by contact name prefix
Firestore.firestore()
    .collection("debriefs")
    .whereField("userId", isEqualTo: userId)
    .whereField("contactName", isGreaterThanOrEqualTo: searchText)
    .whereField("contactName", isLessThan: searchText + "\u{f8ff}")
    .limit(to: 20)
```

### Option C: Full-Text Search Service (Phase 3)
```
┌──────────┐      ┌─────────────┐      ┌──────────────┐
│  Mobile  │─────▶│   Backend   │─────▶│  Algolia /   │
│  Search  │      │   /search   │      │  Typesense   │
└──────────┘      └─────────────┘      └──────────────┘
                                              │
                                              ▼
                                       Indexes transcripts,
                                       summaries, contact names
```

### Option D: Semantic Search (Phase 4)
```
User: "that conversation about the contract"
              │
              ▼
        ┌───────────┐
        │  Embed    │  ← Convert query to vector
        │  Query    │
        └─────┬─────┘
              │
              ▼
        ┌───────────┐
        │  Vector   │  ← Pinecone / Firestore Vector Search
        │  Search   │
        └───────────┘
              │
              ▼
        Find semantically similar debriefs
```

---

## Implementation Phases

### Phase 1: Timeline + Cursor Pagination + Local Filter
**Goal:** Basic infinite scroll timeline with local filtering

**Tasks:**
- [ ] Create `DebriefListViewModel` with cursor pagination
- [ ] Implement `loadFirstPage()` and `loadNextPage()`
- [ ] Build `DebriefListView` with `LazyVStack`
- [ ] Add loading indicator at bottom
- [ ] Implement `loadMoreIfNeeded()` trigger (load when 5 items from end)
- [ ] Add date grouping headers (Today, Yesterday, This Week, etc.)
- [ ] Basic local filter on loaded items

**Firestore Index Required:**
```
Collection: debriefs
Fields: userId (Ascending), createdAt (Descending)
```

---

### Phase 2: People Strip + Contact Filter + Date Filter
**Goal:** Quick access to recent contacts, filter by person and date range

**Tasks:**
- [ ] Query recent contacts (distinct contacts from recent debriefs)
- [ ] Build horizontal scrolling `RecentPeopleStrip` component
- [ ] Show contact avatar/initials + time since last debrief
- [ ] Tap contact → filter timeline to that person only
- [ ] Add "All" option to clear filter
- [ ] Build filter button next to search bar
- [ ] Build filter bottom sheet with sections:
  - [ ] Searchable contact picker (handles 2000+ contacts)
  - [ ] Date range selector (Today, Week, Month, All, Custom)
- [ ] Create `DebriefFilters` model to hold filter state
- [ ] Implement `SearchableContactPicker` component with local search
- [ ] Implement `buildQuery(filters:)` to construct Firestore query
- [ ] Build `ActiveFilterChips` component to show active filters
- [ ] Add "Clear All" functionality
- [ ] Update `DebriefListViewModel` to accept filters and re-query
- [ ] Reset pagination cursor when filters change
- [ ] Show result count when filters are active (e.g., "3 results")
- [ ] Handle empty state when no results match filters

**UI Addition:**
```
┌─────────────────────────────────────────┐
│ RECENT PEOPLE                        ▶  │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │
│ │ All │ │John │ │Sarah│ │ Mom │         │
│ │     │ │ 2h  │ │ 1d  │ │ 3d  │         │
│ └─────┘ └─────┘ └─────┘ └─────┘         │
└─────────────────────────────────────────┘
```

**Firestore Indexes Required:**
```
# Contact + date filter
Collection: debriefs
Fields: userId ASC, contactId ASC, occurredAt DESC

# Date range filter only
Collection: debriefs
Fields: userId ASC, occurredAt DESC
```

---

### Phase 3: Full-Text Search
**Goal:** Search across transcripts and summaries

**Tasks:**
- [ ] Choose search provider (Algolia or Typesense)
- [ ] Set up search index with fields: `transcript`, `summary`, `contactName`
- [ ] Create Cloud Function to sync debriefs → search index on create/update/delete
- [ ] Add backend endpoint `GET /v1/search?q=...` (or use search provider SDK directly)
- [ ] Build search UI with results list
- [ ] Highlight matching text in results
- [ ] Handle empty states and loading

**Search Index Schema:**
```json
{
  "debriefId": "string",
  "userId": "string",
  "contactName": "string",
  "transcript": "string",
  "summary": "string",
  "createdAt": "timestamp"
}
```

---

### Phase 4: Semantic Search
**Goal:** Find debriefs by meaning, not just keywords

**Tasks:**
- [ ] Choose vector database (Pinecone, Firestore Vector Search, etc.)
- [ ] Generate embeddings for each debrief summary (OpenAI embeddings API)
- [ ] Store embeddings in vector database
- [ ] Create Cloud Function to generate embedding on debrief creation
- [ ] Build semantic search endpoint
- [ ] Combine with keyword search for hybrid results

**Example Query:**
```
User types: "the call where we discussed pricing"
→ Even if "pricing" isn't in the transcript, finds debriefs about costs, money, budget, etc.
```

---

## Summary Table

| Concern | Solution |
|---------|----------|
| Infinite scroll performance | Cursor-based pagination with `start(afterDocument:)` |
| Data load on mobile | Only fetch 20 at a time, load on demand with `LazyVStack` |
| Firestore costs | Cursor pagination = pay only for docs you read |
| Person-centric design | People strip at top, filter by contact |
| Filtering | Filter sheet with searchable contact picker + date range |
| Basic search | Local filter + Firestore prefix queries |
| Advanced search | Algolia/Typesense for full-text (Phase 3) |
| Semantic search | Vector embeddings (Phase 4) |

---

## Implementation Phases Summary

| Phase | Feature | Complexity |
|-------|---------|------------|
| **Phase 1** | Timeline + cursor pagination + local filter | Low |
| **Phase 2** | People strip + contact filter + date filter | Low |
| **Phase 3** | Full-text search (Algolia/Typesense) | Medium |
| **Phase 4** | Semantic search (vector embeddings) | High |

---

## Required Firestore Indexes

```
# For timeline pagination
Collection: debriefs
Fields: userId ASC, createdAt DESC

# For contact filter + pagination
Collection: debriefs
Fields: userId ASC, contactId ASC, createdAt DESC

# For date range filter
Collection: debriefs
Fields: userId ASC, occurredAt DESC

# For combined filters (contact + date)
Collection: debriefs
Fields: userId ASC, contactId ASC, occurredAt DESC

# For search by contact name prefix
Collection: debriefs
Fields: userId ASC, contactName ASC
```
