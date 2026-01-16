---
trigger: always_on
---

Offline-First, Reactive Data, and Efficiency Rules

START WITH ORDERS

You are building Debrief as a fast, fluid, offline-first iOS product. The app must feel instant on open. Network is optional. Local data is primary.

1) Offline-first is mandatory
	•	The UI must render from local cache first.
	•	Network fetches are used to refresh, not to unblock first paint.
	•	If there is no cached data, show an empty state immediately, then load asynchronously.
	•	The app must remain functional with no network. Any feature that cannot work offline must degrade gracefully and explain why.

2) Data flow contract (single source of truth)
	•	Use a single source of truth for UI state.
	•	Persist debriefs, people links, and metadata locally.
	•	The UI observes local state and updates automatically when the store changes.
	•	Server sync, if present, writes into the same store and triggers UI updates.

3) Reactive updates must be correct and efficient
	•	When new data is added or updated, the UI must update without manual refresh hacks.
	•	Use reactive patterns intentionally:
	•	Combine or Swift Concurrency streams are allowed.
	•	Avoid mixing patterns randomly.
	•	No excessive recomputation:
	•	Do not rebuild large view state on every small change.
	•	Use incremental updates where possible.
	•	Debounce or throttle high-frequency signals.

4) Refresh policy (stability and cost aware)
	•	Refresh must be:
	•	Opportunistic, not constant.
	•	Cancelable.
	•	Debounced when triggered repeatedly.
	•	Prefer “stale-while-revalidate” behavior:
	•	Show cached immediately.
	•	Refresh in background.
	•	Merge results and update UI only if changes exist.
	•	Avoid tight polling loops. Use explicit triggers and sensible intervals only if required.

5) Cache design rules
	•	Define cache ownership:
	•	What is cached.
	•	TTL or invalidation strategy.
	•	Conflict resolution approach if syncing exists.
	•	Cache must be bounded. Avoid unbounded growth.
	•	Large payloads must be stored efficiently and loaded lazily.

6) Efficiency and “green code” discipline
	•	Optimize for battery and heat:
	•	Minimize background work.
	•	Avoid frequent timers.
	•	Avoid repeated heavy transforms.
	•	Prefer lazy loading and pagination for large lists.
	•	Prefer fewer writes. Batch writes when safe.
	•	Prefer fewer network calls. Coalesce requests and reuse results.

7) UI-first startup performance

On app launch or screen entry:
	•	Render something immediately.
	•	Load cached data first.
	•	Defer non-critical work.
	•	Never block main thread with cache reads, parsing, or mapping.
	•	Any expensive work must be off-main and cancelable.

8) Streaming and partial updates preparation
	•	Current scope may summarize “all at once,” but new work must not block future partial or incremental updates.
	•	New features must keep data flow modular:
	•	Separate recording state from summary state.
	•	Separate local draft state from finalized persisted entities.
	•	Avoid designs that require rewriting the entire flow later.

9) Verification checklist for every feature change

Before finishing any implementation, verify:
	•	App works without network.
	•	UI loads from cache first.
	•	Background refresh does not freeze UI.
	•	Updates propagate reactively without manual reload hacks.
	•	Refresh is debounced and cancelable.
	•	Cache has an invalidation or consistency strategy.
	•	No unbounded growth in memory, disk, or network calls.

10) Output requirement

When implementing data flow changes, you must state:
	•	What is cached locally.
	•	What triggers refresh.
	•	What runs on background vs main.
	•	How the UI gets updates reactively.
	•	How cancellation is handled.