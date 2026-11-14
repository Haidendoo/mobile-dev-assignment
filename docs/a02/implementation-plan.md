# A02 implementation baseline

Decision date: 14 November 2026 (Asia/Bangkok). Two members; four relative work
weeks, approximately 15–20 hours/member/week. Exact course dates remain unknown.
English application and documentation. Android 10+, landscape; Windows development,
emulator-first testing, borrowed Android hardware for final NFR measurements.

## Source of truth

The updated report is `rp/A1_Mobile_dev.zip`, especially its assembled English
sections, Section 6 API contract, and v1.1 canonical-map appendix. The copy at
`docs/a02/openapi.json` is the updated design contract, not a deployed API.
`app/assets/data/levels.json` contains all twelve corresponding maps/solutions.
The older `docs/A01-specification.md`, `data/levels.json`, `prototype/` and generated
`deliverables/Forest-Sokoban-A01.*` remain historical five-level A01 artifacts.
The old Python build generator does not regenerate the A02 application or its
contract. Do not treat old generated acceptance counts as current A02 results.

## Release scope

All 27 Must requirements remain required: twelve levels, three chapters, offline
story and ending, game rules, Undo/Restart/pause, reliable save/resume, Music/SFX,
casual rankings, anonymous identity, same-ID email linking, OTP sign-in, and
asynchronous server-verified two-player challenges. Target all four Should
refinements: separate volume sliders, terminal-room history, archive thumbnails
with chapter filters, and short reduced-motion-aware animations.

Could requirements FR-17 (haptics) and FR-29 (campaign cloud sync) are excluded.
Email recovery restores online ownership, not local campaign progress. Changes
to requirements, architecture, content versions, API or UI require a recorded
rationale and affected tests; the team must review design deviations.

## Architecture and contract

Flutter/Dart, ChangeNotifier MVVM, pure rules, constructor injection, repositories,
SQLite, secure OS session storage, audio service, Supabase Auth/PostgreSQL/RLS/RPCs,
and a TypeScript Edge replay validator. Views never access storage or APIs.
SQLite commit precedes board acknowledgement. Completion atomically updates best
pair/progress/outbox and removes the unfinished save. Time is monotonic and active
only; restoration is paused. Campaign and account/room challenge namespaces stay
separate. Shared fixtures must prove Dart/server replay parity.

Implement the supplied contract: submit_score, get_leaderboard, create_challenge,
join_challenge, get_challenge_status, list_my_challenges, cancel_challenge, and the
submit-challenge Edge Function. Ownership derives from authenticated claims;
client roles cannot execute privileged finalization. Room joins/submissions are
atomic, server deadlines authoritative, retries use fixed IDs/payloads, and accepted
duplicate receipts remain retrievable after expiry. Never label casual rankings
as verified. No polling or background worker.

## Milestones

| Week | Member A | Member B | Exit |
|---|---|---|---|
| 1 | Toolchain, CI, rules, SQLite, unit tests | Content/design alignment, shared UI, gameplay, Auth spike with A | Runnable foundation; local same-ID linking proof |
| 2 | Completion/progression, score outbox/RPCs, room foundations | Full campaign/story/audio/settings, rankings/Profile/OTP | Preliminary APK, live scores and hosted OTP; mid-term walkthrough |
| 3 | Room RPCs, RLS, Edge replay/finalizer, concurrency tests | Challenge UI and queues, account isolation, Should refinements | Two-client verified challenge; feature complete |
| 4 | Integration/security/performance fixes, clean build | Manual/layout tests, evidence, README and demo | Final signed release APK and acceptance package |

Review PRs throughout the schedule. Keep main buildable and contributions honest;
do not manufacture commits, reviewers, sessions or results. Reserve the final two
working days for fixes and submission. Defer Should polish with its specified
fallback before proposing any Must reduction.

## Verification and handoff

Trace Requirement → AC → Component → Test → Result → Evidence → Commit.
Execute unit, widget, database-fault, API/RLS, concurrency, deadline, owner-switch,
offline/kill and manual acceptance tests. Verify all twelve reference solutions,
all Must/Should ACs and 21 NFR records. Check 640×360/800×450 dp, 1.3x text,
TalkBack, safe insets, OTP keyboard, and real-device release performance.

Deliver installable APK/checksum, reproducible README, test report, change log,
traceability, asset sources, contribution/AI declarations and a rehearsed demo.
A fresh checkout must build/run following README (A02 build-failure cap: 40/100).
Windows runtime, physical-device tests and hosted integrations require actual
execution; host Dart tests and an APK build cannot stand in for that evidence.
