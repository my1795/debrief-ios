---
trigger: always_on
---

Product context you must always respect

Product Name: Debrief
Category: Post-call personal memory assistant
Platform: iOS (initial focus)
Business Model: Subscription-based
Growth Model: Product-Led Growth (PLG)

Debrief exists to capture human insight immediately after phone calls, when memory is still fresh. Speed, frictionlessness, and trust are critical.

This context must inform every technical decision you make.

⸻

The problem you are solving
	•	Users forget important details immediately after calls.
	•	Notes are delayed or never written.
	•	Context between conversations is lost.
	•	Follow-ups become weak and generic.

The problem is not documentation quality.
The problem is timing.

Your code must optimize for immediacy, low friction, and habit formation.

⸻

The solution you are implementing
	•	Debrief triggers immediately when a phone call ends.
	•	The user records a short voice debrief, in their own words.
	•	No typing. No friction.
	•	AI structures thoughts into summaries and action points.
	•	Debriefs are linked to people, not just calls.
	•	No call audio is ever recorded. Privacy is fundamental.

If a technical decision increases friction, delays the flow, or weakens privacy, it is wrong.

⸻

Core product principles (hard constraints)

You must enforce these principles in code, UX, and architecture:
	•	Call-triggered, not manual
	•	Voice-first, not text-first
	•	Person-centric, not call-centric
	•	Privacy-first by design
	•	Zero behavior change required

Debrief must fit into existing user habits.
It must never feel like “extra work.”

⸻

What Debrief is
	•	A personal conversation memory tool
	•	A post-call reflection assistant
	•	A lightweight intelligence layer over real conversations

What Debrief is not
	•	Not a call recorder
	•	Not a meeting bot
	•	Not a CRM
	•	Not a team collaboration tool

Do not design or code toward CRM-like workflows, team features, or heavy data entry.

⸻

Core loop you must preserve
	1.	Call ends
	2.	Prompt appears immediately
	3.	User records a short voice debrief
	4.	AI structures it
	5.	Debrief is linked to the person
	6.	User revisits context before the next interaction

Any implementation that breaks, delays, or complicates this loop is unacceptable.

⸻

Engineering and architecture rules

Platform and language
	•	Use modern Swift.
	•	Target iPhone 15 and newer models.
	•	Assume long-term maintenance and iteration.

Architecture
	•	MVVM is mandatory.
	•	Views render state only.
	•	ViewModels manage state, async flows, and presentation logic.
	•	Models are domain-only.
	•	Side effects live in services.
	•	Use dependency injection.
	•	Avoid hidden globals and unnecessary singletons.

⸻

Code quality standards
	•	Production-ready code only.
	•	Clarity over cleverness.
	•	No over-engineering.
	•	No complexity added “just in case.”
	•	No premature abstractions.
	•	No external libraries unless clearly justified by product needs.

⸻

File and scope control
	•	Maximum 10 files per response, new or modified.
	•	If more than 10 files are required:
	•	You must warn explicitly.
	•	You must propose a chunked implementation plan.
	•	You must implement only one chunk at a time.
	•	Each chunk must be coherent and usable on its own.

⸻

Performance and resource discipline
	•	Be mindful of memory, CPU, battery, and network usage.
	•	Avoid unnecessary main-thread work.
	•	Manage async tasks and cancellation correctly.
	•	Never leak resources.
	•	Optimize for fast post-call responsiveness.

⸻

Apple platform compliance
	•	When working with system APIs, permissions, background behavior, audio, CallKit, or App Store constraints:
	•	Prefer official Apple Developer documentation.
	•	If uncertain, choose the safest, most compliant approach.

⸻

PLG and subscription mindset
	•	Every feature must support:
	•	Habit formation
	•	Retention
	•	Trust
	•	Long-term personal value
	•	Avoid dark patterns, forced upsells, or artificial friction.
	•	Respect the user’s time and attention.

⸻

Response format (mandatory)

For any implementation response, you must structure it as:
	1.	Scope of this chunk
	2.	Files changed (max 10)
	3.	Key technical decisions
	4.	Code, organized by file
	5.	Next chunk (if applicable)
