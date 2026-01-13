# Debrief App - Complete UI/UX Documentation

## 🎨 Design System

### Color Palette
**Primary Gradient (Background):**
- `from-teal-900` → `via-teal-800` → `to-emerald-900`
- Koyu yeşilimsi/teal gradient (SKIFI app style)

**Glassmorphism Containers:**
- Background: `bg-white/10` (10% opacity beyaz)
- Backdrop blur: `backdrop-blur-md`
- Border: `border border-white/20`
- Hover: `hover:bg-white/20`

**Text Colors:**
- Primary: `text-white`
- Secondary: `text-white/70`
- Tertiary: `text-white/60`
- Muted: `text-white/40`

**Accent Colors:**
- Teal: `text-teal-300` (icons, highlights)
- Green Success: `bg-green-500/30` with `border-green-400/50`
- Red Error: `bg-red-500/20` with `border-red-400/30`
- Yellow Warning: `bg-yellow-500/20` with `border-yellow-400/30`

**UI Elements:**
- Rounded corners: `rounded-xl` (12px)
- Card rounded: `rounded-lg` (8px)
- Shadows: Soft, minimal (glassmorphism style)
- Transitions: `transition-all` or `transition-colors`

---

## 📱 Screen Breakdown

### 1. DEBRIEFS LIST (Ana Ekran)

**Layout:**
```
┌─────────────────────────────┐
│ [Debriefs]      [📝1/📞8 ⏱️] │ ← Header + Status Bar
│ [Search...] [Sort 🎛️]       │ ← Search + Sort
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Contact Name     [READY]│ │ ← Debrief Card
│ │ 📅 Date | ⏱️ Duration    │ │
│ │ Summary preview...      │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ...                     │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [🏠] [👥] [🎙️] [📊] [⚙️]    │ ← Bottom Navigation
└─────────────────────────────┘
```

**Features:**
- **Header:** "Debriefs" title (3xl, bold, white)
- **Status Bar Widgets:** Apple Mac status bar style
  - `📝 1 / 📞 8` (today calls / total calls)
  - `⏱️ 142 min` (total minutes)
  - Glassmorphism badges: `bg-white/10 backdrop-blur-md px-2.5 py-1.5 rounded-lg`

- **Search:** 
  - Placeholder: "Search debriefs..."
  - Icon: Search icon (teal-300)
  - Glassmorphism input

- **Sort Menu:**
  - Options: Most Recent, Oldest, Duration, Contact Name, Status
  - Dropdown overlay: `bg-teal-950/95 backdrop-blur-md`

- **Debrief Cards:**
  - Container: Glassmorphism (`bg-white/10 backdrop-blur-md border border-white/20`)
  - Status Badge: DRAFT, UPLOADED, PROCESSING, READY, FAILED
  - Date format: "Today", "Yesterday", "3 days ago"
  - Duration: "2:45" format
  - Summary: Truncated preview text

**Status Badge Colors:**
- DRAFT: `bg-gray-500/20 text-gray-300`
- UPLOADED: `bg-blue-500/20 text-blue-300`
- PROCESSING: `bg-yellow-500/20 text-yellow-300`
- READY: `bg-green-500/20 text-green-300`
- FAILED: `bg-red-500/20 text-red-300`

**Empty State:**
- Icon: Large Mic icon (teal-300)
- Text: "No debriefs yet"
- CTA: "Tap + to record your first debrief"

---

### 2. DEBRIEF DETAIL

**Layout:**
```
┌─────────────────────────────┐
│ [←] Contact Name    [READY] │ ← Header
│ 📅 Date | ⏱️ Duration         │ ← Meta info
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Summary                 │ │ ← Summary Card
│ │ Lorem ipsum dolor...    │ │
│ └──────────────────��──────┘ │
│ ┌─────────────────────────┐ │
│ │ Action Items            │ │ ← Action Items Card
│ │ • Follow up on project  │ │
│ │ • Send email to client  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Transcript              │ │ ← Transcript Card
│ │ Full transcript text... │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Audio Recording         │ │ ← Audio Player Card
│ │ [▶️] ━━━━━━━━━ 2:45     │ │
│ └─────────────────────────┘ │
│ [Export 🔗] [🗑️]           │ ← Action Buttons
└─────────────────────────────┘
```

**Features:**
- **Header:** Back button + Contact name + Status badge
- **Meta Info:** Date (long format) + Duration
- **Cards:** All use glassmorphism containers
- **Status Messages:**
  - FAILED: Red card with "Retry Processing" button
  - PROCESSING: Yellow card with "Processing Audio..." message
- **Audio Player:**
  - Play/Pause button (teal-500)
  - Progress bar (teal-400)
  - Time display (current / total)
- **Action Buttons:**
  - Export: Teal background (`bg-teal-500`)
  - Delete: Red transparent (`bg-red-500/20 border-red-400/30`)
- **Delete Modal:**
  - Dark overlay (`bg-black/50 backdrop-blur-sm`)
  - Dialog: `bg-teal-950/95 backdrop-blur-md`
  - Cancel + Delete buttons

---

### 3. RECORD SCREEN (4 States)

#### STATE 1: RECORDING (Auto-start)
```
┌─────────────────────────────┐
│                             │
│         🎙️ (Pulsing)        │ ← Red circle, animate-pulse
│                             │
│      Recording...           │
│                             │
│         05:23               │ ← Large timer (white, 4xl)
│                             │
│    [⏹️ Stop Recording]      │ ← Stop button
│                             │
└─────────────────────────────┘
```

**Features:**
- Auto-starts when screen opens
- Timer auto-increments (useEffect)
- Red pulsing mic icon (`bg-red-500 animate-pulse`)
- Large time display (MM:SS format)
- Stop button: Glassmorphism style

---

#### STATE 2: SELECT CONTACT
```
┌─────────────────────────────┐
│ Recording Saved!            │ ← Header
│ Duration: 05:23             │ ← Saved duration display
│ Select a contact for this...│
│ [🔍 Search contacts...]     │ ← Search
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ John Doe         [✓]    │ │ ← Contact (selected)
│ │ @johndoe                │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Jane Smith              │ │
│ │ Acme Corp               │ │
│ └─────────────────────────┘ │
│ [+ Create New Contact]      │ ← Dashed button
├─────────────────────────────┤
│ [✓ Save Debrief]           │ ← Save button (bottom)
└─────────────────────────────┘
```

**Features:**
- Shows recording duration at top
- Search contacts with filter
- Selected contact: `bg-teal-400/30 border-teal-300/50` + checkmark
- Unselected: `bg-white/10 border-white/20`
- Create New Contact: Dashed border, opens form inline
- **New Contact Form:**
  - Name input (required)
  - Company input (optional)
  - Cancel + Create buttons
- Save button: Only enabled when contact selected

---

#### STATE 3: PROCESSING
```
┌─────────────────────────────┐
│                             │
│     ⚙️ (Spinning loader)    │ ← Teal spinner
│                             │
│      Processing...          │
│   Uploading and processing  │
│      your debrief           │
│                             │
└─────────────────────────────┘
```

**Features:**
- Spinner: `border-4 border-teal-300 border-t-transparent animate-spin`
- Container: `bg-teal-500/30 backdrop-blur-md border-teal-400/50`

---

#### STATE 4: COMPLETE
```
┌─────────────────────────────┐
│                             │
│         ✓ (Green)           │ ← Green checkmark
│                             │
│       Complete!             │
│   Your debrief has been     │
│         saved               │
│                             │
└─────────────────────────────┘
```

**Features:**
- Checkmark: `text-green-300`
- Container: `bg-green-500/30 border-green-400/50`
- Auto-redirects to Debriefs List after 2s

---

### 4. CONTACTS LIST

**Layout:**
```
┌─────────────────────────────┐
│ Contacts                    │ ← Header
│ [🔍 Search contacts...]     │ ← Search
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ [👤] John Doe           │ │ ← Contact Card
│ │      @johndoe           │ │
│ │      8 debriefs • 2d ago│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ [👤] Jane Smith         │ │
│ │      Acme Corp          │ │
│ │      3 debriefs • Today │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**Features:**
- Avatar: Circular, teal background (`bg-teal-400/30`)
- Contact name: Bold white
- Handle/Company: Secondary white (70%)
- Stats: Debrief count + Last contacted
- Date format: "Today", "Yesterday", "2 days ago", "Jan 13"
- Empty state: "No contacts found"

---

### 5. STATS

**Layout:**
```
┌─────────────────────────────┐
│ Stats                       │ ← Header
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🏆 Current Plan         │ │ ← Plan Card (gradient)
│ │ Pro                     │ │
│ │ All features unlocked   │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 📈 This Week            │ │ ← Week Stats
│ │  12    142    23        │ │
│ │ Debriefs Minutes Actions│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 📅 This Month           │ │ ← Month Stats
│ │  45    523    89        │ │
│ │ Debriefs Minutes Actions│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ⚡ Quota Usage          │ │ ← Quota
│ │ Recordings: 45/100      │ │
│ │ ━━━━━━━━━━ 45%         │ │
│ │ Minutes: 523/1000       │ │
│ │ ━━━━━━━━━━ 52%         │ │
│ │ Storage: 1.2GB/5GB      │ │
│ │ ━━━━━━━━━━ 24%         │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Recent Activity (Chart) │ │ ← Bar Chart
│ │     ▃ ▅ ▇ ▄ ▆ ▃ ▅      │ │
│ │     M T W T F S S       │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**Features:**
- **Current Plan:** Gradient card (`from-teal-500 to-emerald-500`)
- **Stats Cards:** 3-column grid with large numbers
- **Quota Bars:**
  - Progress bar: Teal (`bg-teal-400`) if under 80%
  - Progress bar: Red (`bg-red-400`) if over 80%
  - Container: `bg-white/20`
- **Activity Chart:**
  - Bar chart with hover effect
  - Bars: `bg-teal-400 hover:bg-teal-300`
  - Height: Proportional to max value

---

### 6. SETTINGS

**Layout:**
```
┌─────────────────────────────┐
│ Settings                    │ ← Header
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🔐 Privacy First        │ │ ← Notice Banner
│ │ This app is designed... │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 👤 Account              │ │ ← Section
│ │ Profile              >  │ │
│ │ Email & Notifications > │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 💳 Plan & Billing       │ │ ← Section
│ │ Current Plan: Pro    >  │ │
│ │ Upgrade Plan         >  │ │
│ │ Billing History      >  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🛡️ Privacy & Data       │ │ ← Section
│ │ Privacy Policy       ↗  │ │
│ │ Data Handling        >  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 💾 Storage              │ │ ← Section
│ │ Audio Storage: 1.2GB >  │ │
│ │ Clear Cache          >  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ❓ Support              │ │ ← Section
│ │ Help Center          ↗  │ │
│ │ Contact Support      >  │ │
│ │ Send Feedback        >  │ │
│ └─────────────────────────┘ │
│                             │
│ Debrief App v1.0.0          │ ← Footer
│ © 2026 All rights reserved  │
└─────────────────────────────┘
```

**Features:**
- **Privacy Banner:** Teal accent (`bg-teal-400/20 border-teal-300/30`)
- **Section Headers:** Icon + Title (bold white)
- **List Items:**
  - Hover: `hover:bg-white/10`
  - Border between: `border-b border-white/10`
  - Right arrow: `>` (ChevronRight icon)
  - External link: `↗` (ExternalLink icon)
  - Value display: Some items show current value (e.g., "Pro", "1.2GB")

---

## 🎯 Bottom Navigation (Tab Bar)

**Icons:**
- 🏠 Debriefs (Home)
- 👥 Contacts
- 🎙️ Record (Center, larger, primary)
- 📊 Stats
- ⚙️ Settings

**Styling:**
- Active: `text-teal-300` with filled icon
- Inactive: `text-white/60` with outline icon
- Record button: Larger size, may have special treatment
- Background: Glassmorphism bar at bottom

---

## 📊 Data Types & States

### Debrief Status Flow
```
DRAFT → UPLOADED → PROCESSING → READY
                              ↓
                           FAILED (can retry)
```

### Recording Flow
```
1. Click Record → RECORDING (auto-start timer)
2. Click Stop → SELECT_CONTACT (show saved duration)
3. Select contact + Save → PROCESSING
4. Wait → COMPLETE
5. Auto-redirect → Debriefs List
```

### Date Formatting
- Today: "Today"
- Yesterday: "Yesterday"
- 2-6 days: "X days ago"
- 7+ days: "Jan 13"
- Full: "Monday, January 13, 2026, 2:30 PM"

### Duration Formatting
- Format: "MM:SS" (e.g., "2:45")
- Under 1 min: "0:42"
- Over 1 hour: "72:15" (not "1:12:15")

---

## 🎨 Component Patterns

### Glassmorphism Card
```css
bg-white/10 
backdrop-blur-md 
border border-white/20 
rounded-xl 
p-4
hover:bg-white/20 
transition-all
```

### Primary Button
```css
bg-teal-500 
text-white 
rounded-xl 
px-6 py-4 
hover:bg-teal-600 
transition-colors
```

### Secondary Button
```css
bg-white/10 
text-white 
border border-white/20 
rounded-xl 
px-6 py-4 
hover:bg-white/20 
transition-colors
```

### Input Field
```css
bg-white/10 
backdrop-blur-md 
border border-white/20 
rounded-lg 
px-4 py-2.5 
focus:outline-none 
focus:ring-2 
focus:ring-teal-400/50 
placeholder-white/40 
text-white
```

### Status Badge
```css
/* Base */
px-2.5 py-1 
rounded-lg 
text-xs 
font-semibold

/* READY example */
bg-green-500/20 
text-green-300 
border border-green-400/30
```

### Modal Overlay
```css
/* Overlay */
fixed inset-0 
bg-black/50 
backdrop-blur-sm 
z-50

/* Dialog */
bg-teal-950/95 
backdrop-blur-md 
border border-white/20 
rounded-xl 
p-6
```

---

## 💡 Key UX Patterns

1. **Immediate Feedback:** All actions show instant visual feedback (hover, press states)
2. **Loading States:** Always show processing/loading indicators
3. **Empty States:** Helpful messages with CTAs when no data
4. **Error States:** Clear error messages with retry options
5. **Confirmation Dialogs:** For destructive actions (delete)
6. **Search & Filter:** Always debounced, instant results
7. **Auto-scroll:** New items appear at top, auto-focus
8. **Gesture Support:** Swipe actions, pull to refresh (consider for mobile)

---

## 🚀 Animation Guidelines

**Micro-interactions:**
- Button hover: 150ms ease
- Card hover: 200ms ease
- Modal appear: 250ms ease with backdrop blur
- Page transition: 300ms ease

**Loading Animations:**
- Pulse: `animate-pulse` (2s infinite)
- Spin: `animate-spin` (1s linear infinite)
- Fade in: opacity 0 → 1 (300ms)

**Gesture Animations:**
- Swipe threshold: 50px
- Velocity: 0.3s ease-out
- Spring: damping 0.8, stiffness 100 (if using spring physics)

---

## 📱 iOS Implementation Notes

### SwiftUI Equivalents

**Glassmorphism:**
```swift
.background(.ultraThinMaterial) // or .thinMaterial
.background(Color.white.opacity(0.1))
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.2), lineWidth: 1)
)
```

**Gradient Background:**
```swift
LinearGradient(
    colors: [
        Color(hex: "#134e4a"), // teal-900
        Color(hex: "#115e59"), // teal-800
        Color(hex: "#064e3b")  // emerald-900
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**Bottom Navigation:**
```swift
TabView {
    DebriefsList().tabItem { Label("Debriefs", systemImage: "house") }
    ContactsList().tabItem { Label("Contacts", systemImage: "person.2") }
    RecordView().tabItem { Label("Record", systemImage: "mic.circle.fill") }
    StatsView().tabItem { Label("Stats", systemImage: "chart.bar") }
    SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
}
.accentColor(Color(hex: "#5eead4")) // teal-300
```

**Status Badge:**
```swift
Text("READY")
    .font(.caption)
    .fontWeight(.semibold)
    .foregroundColor(Color(hex: "#6ee7b7")) // green-300
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(Color(hex: "#22c55e").opacity(0.2)) // green-500/20
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color(hex: "#4ade80").opacity(0.3), lineWidth: 1) // green-400/30
    )
    .cornerRadius(8)
```

### Recommended iOS Libraries
- **Recording:** AVFoundation
- **Storage:** Firebase Storage or CloudKit
- **Database:** Firebase Firestore or Supabase
- **Charts:** Swift Charts (iOS 16+)
- **Audio Player:** AVAudioPlayer
- **Blur Effects:** Material effects (built-in)

---

## 🎯 Mock Data Structure

### Debrief Object
```typescript
{
  debriefId: "debrief-uuid",
  contactId: "contact-uuid",
  contactName: "John Doe",
  occurredAt: "2026-01-13T14:30:00Z",
  duration: 165, // seconds
  status: "READY", // DRAFT | UPLOADED | PROCESSING | READY | FAILED
  audioUrl: "https://...",
  summary: "Discussed project timeline...",
  transcript: "Full transcript text...",
  actionItems: ["Follow up on X", "Send email to Y"],
  createdAt: "2026-01-13T14:30:00Z",
  updatedAt: "2026-01-13T14:35:00Z"
}
```

### Contact Object
```typescript
{
  contactId: "contact-uuid",
  name: "John Doe",
  handle: "@johndoe", // optional
  totalDebriefs: 8,
  lastContactedAt: "2026-01-11T10:00:00Z", // optional
  relationshipStatus: "Client" // optional
}
```

### Quota Object
```typescript
{
  tier: "Pro",
  recordingsThisMonth: 45,
  recordingsLimit: 100,
  minutesThisMonth: 523,
  minutesLimit: 1000,
  storageUsedMB: 1200,
  storageLimitMB: 5000
}
```

---

## ✅ Implementation Checklist

### Phase 1: Core UI
- [ ] Setup project with SwiftUI
- [ ] Implement gradient background
- [ ] Create glassmorphism component library
- [ ] Build bottom navigation TabView
- [ ] Implement Debriefs List
- [ ] Implement Debrief Detail

### Phase 2: Recording
- [ ] Setup AVFoundation for recording
- [ ] Build Recording screen (4 states)
- [ ] Implement timer logic
- [ ] Contact picker integration
- [ ] Audio upload flow

### Phase 3: Data & Storage
- [ ] Setup Firebase/Supabase
- [ ] Implement data models
- [ ] Audio storage integration
- [ ] Implement AI processing (OpenAI Whisper API)
- [ ] Local caching strategy

### Phase 4: Additional Screens
- [ ] Contacts List
- [ ] Stats with charts
- [ ] Settings screen
- [ ] Profile management

### Phase 5: Polish
- [ ] Animations & transitions
- [ ] Error handling & retry logic
- [ ] Empty states
- [ ] Loading states
- [ ] Offline support
- [ ] Push notifications
- [ ] App icon & splash screen

---

## 🔗 Resources

**Design Inspiration:**
- Apple Music/Podcasts app (glassmorphism)
- SKIFI app (teal gradient palette)
- iOS Human Interface Guidelines

**APIs to Consider:**
- OpenAI Whisper API (transcription)
- OpenAI GPT-4 API (summary + action items)
- Firebase (storage + database)
- Supabase (alternative to Firebase)

**Color Palette Reference:**
- Teal-900: #134e4a
- Teal-800: #115e59
- Teal-500: #14b8a6
- Teal-400: #2dd4bf
- Teal-300: #5eead4
- Emerald-900: #064e3b
- White with opacity: Use Color.white.opacity(0.1-0.9)

---

## 📸 Screenshot Checklist

Screenshot these screens for iOS reference:

1. ✅ Debriefs List (with data)
2. ✅ Debriefs List (empty state)
3. ✅ Debriefs List (search active)
4. ✅ Debriefs List (sort menu open)
5. ✅ Debrief Detail (READY status)
6. ✅ Debrief Detail (FAILED status with retry)
7. ✅ Debrief Detail (PROCESSING status)
8. ✅ Record Screen - Recording (timer running)
9. ✅ Record Screen - Select Contact
10. ✅ Record Screen - Select Contact (new contact form)
11. ✅ Record Screen - Processing
12. ✅ Record Screen - Complete
13. ✅ Contacts List (with data)
14. ✅ Stats Screen (all cards visible)
15. ✅ Settings Screen (all sections visible)
16. ✅ Delete confirmation modal
17. ✅ Bottom navigation (all tabs)

---

**End of Documentation** 🎉

Last updated: January 13, 2026
Version: 1.0.0
