# Forest Sokoban

## Comprehensive Specification and Design — Assignment 01

Version: **1.0-draft**. Prepared: **21 October 2026**, Asia/Bangkok. Language: **English**. Team: **Member A / Member B — names pending**. Approval: **pending both members**.

This consolidated document is the proposed acceptance baseline for A02. It includes requirements, architecture, data/API design, high-fidelity screen designs, traceability, test design, and evidence appendices. The PDF embeds the generated diagrams and screen assets.

**Submission readiness:** desk research and design artifacts are available. Participant interviews, evidence-backed personas, usability sessions, and a published Figma prototype URL are pending. Blank research forms are not evidence of completed research. No Flutter app or deployed backend is claimed.

## Contents

1. Product definition and fixed rules
2. Problem analysis and requirements elicitation
3. Functional requirements and acceptance criteria
4. Use cases and user flows
5. Non-functional requirements and mobile constraints
6. System and in-app architecture
7. Data model and persistence
8. API contract and security
9. UI/UX and clickable prototype
10. Traceability and verification
11. Delivery, change control, and A02 handoff
12. Evidence, attribution, and declarations

## 1. Product definition and fixed rules

### 1.1 Product goal

Forest Sokoban is a single-player, top-down, landscape mobile puzzle game for students who want a short, interruption-friendly game. Players walk through small forest clearings and push crates onto marked goals. All five levels are playable without a network connection, including the first launch. An optional-to-use online leaderboard adds comparison without an email-registration flow.

The two-person team will design five original fixed levels, a small set of reusable screens, and a limited Supabase integration. The submitted screenshot informs the visual direction only. The original reference website could not be inspected; its rules and assets are not claimed as reproduced. The agreed rules below define this project.

### 1.2 Rules and score semantics

- The board is a rectangular grid of at most 10 columns by 8 rows. Coordinates are zero-based [x, y], starting at the upper-left; y increases downward.
- Each level has one player, 1–4 crates, an equal number of goals, floor, and impassable walls. Decorations outside the board never affect collision.
- A directional tap requests exactly one orthogonal move. No diagonal movement, pulling, multi-crate pushes, swipe navigation, or hold-to-repeat is required.
- A player can enter floor or an unoccupied goal. A crate can be pushed only if the cell beyond it is traversable and contains no crate.
- Blocked input changes neither positions, undo history, nor action count. Brief visual feedback explains the blocked action.
- A successful move or push adds one action to the displayed Steps counter. A successful undo restores the preceding board snapshot and also adds one action. An empty-history undo is disabled. Undo never subtracts time or actions and has no redo branch.
- Winning occurs immediately when every crate occupies a goal. Completion freezes movement/time and creates one result. A completed board cannot be undone; Replay starts a new attempt.
- Time is measured in active-play milliseconds using a monotonic clock; display is mm:ss. Time starts when gameplay becomes active and pauses while dialogs, pause, background, or completion are shown. Opening a level counts as active play even before the first move.
- Restart requires confirmation and creates a fresh attempt with zero steps, zero elapsed time, empty history, and initial positions. Cancel returns to the prior state.
- All five levels are selectable immediately. Completing them records personal bests; there is no unlock tree, lives system, time limit, or automatic deadlock detector.
- A deadlock can be recovered with Undo or Restart. The guide demonstrates why a crate in a non-goal corner can become stuck.
- Online ranking is per level and level version: steps ascending, elapsed milliseconds ascending, then server receipt timestamp ascending, then submission UUID ascending for a deterministic final tie. One best row is returned per guest.
- A worse or equal later result never replaces a better result. Local best comparison uses the same steps/time pair. Server receipt time, not device time, resolves online ties.
- Network access is never necessary to start or finish a level. Submission is automatic when feasible; failures leave an explicitly pending local result.

### 1.3 Original level catalogue

The canonical file is `data/levels.json`. Legend: # wall; space floor; . goal; $ crate; @ player; * crate on goal; + player on goal. U/D/L/R encode one valid directional action.

| Level/version | Name | Board | Crates | Reference solution | Steps | Learning objective |
|---|---|---|---|---|---|---|
| L01/1 | First Steps | 7 x 5 | 1 | RR | 2 | Straight-line push |
| L02/1 | Around the Bend | 7 x 6 | 1 | URDRUU | 6 | Reposition around a crate |
| L03/1 | Two Deliveries | 8 x 7 | 2 | LUUDDRRRUU | 10 | Route between crates |
| L04/1 | Forest Divider | 9 x 7 | 2 | LLUUDDRRRRUU | 12 | Navigate a central wall |
| L05/1 | Three Clearings | 10 x 8 | 3 | LULUUDRRLDDRRUUUDRDRUULUL | 25 | Plan several deliveries |

The design-verification script replays each solution and independently searches for the shortest move solution. Increasing shortest paths support the proposed ordering, but perceived difficulty still needs participant feedback. These tiny maps deliberately keep scope manageable. The supported maximum of four crates is not a promise to include a four-crate level.

![Original level layouts and reference solutions](assets/level-catalogue.svg)

## 2. Problem analysis and requirements elicitation

### 2.1 Problem statement and stakeholders

**Working hypothesis:** students taking short breaks may want a simple puzzle that tolerates interruptions, has clear touch controls, and remains available with unreliable connectivity. This is a design hypothesis, not a surveyed conclusion or a claim of medical/cognitive benefit.

| Stakeholder | Interest | Involvement |
|---|---|---|
| Student players | Learn quickly, recover mistakes, resume interrupted play | Interviews and prototype tasks |
| Two team members | Scope that can be designed and built within the course | Shared decisions and cross-review |
| Course assessor | Verifiable requirements, coherent design, explainable implementation | A01/A02 review |
| Backend project owner | Safe credentials and controlled writes | Own Supabase configuration at A02 |

Success for A01 means a coherent specification and usable prototype with authentic evidence and complete traceability. Success for A02 means every Must and the sound-related Should acceptance criteria pass, with actual backend integration and a reproducible build.

### 2.2 Elicitation method and evidence boundaries

Recruit 3–5 student volunteers for 10–15 minute interviews. Ask about actual recent play, break duration, network problems, recovery expectations, and accessibility before presenting the concept. Obtain consent for anonymized notes; collect no unnecessary identity data. Preserve observations separately from interpretations.

Evidence IDs P01–P05 and findings F-xxx are reserved in the supplied CSV templates. Sessions are **not conducted**. Populate dates, notes, requirement links, and decisions after the sessions. Do not invent participant statements or consensus. After interviews, revise the following proto-personas and cite the supporting participant IDs.

### 2.3 Provisional proto-personas

| Sketch | Hypothesized context | Need to validate | Candidate requirements |
|---|---|---|---|
| PP-01: The interrupted player | Student playing between classes with inconsistent connectivity | Wants quick entry, local resume, and no registration barrier | FR-01, FR-08, FR-09, FR-11 |
| PP-02: The improving puzzler | Student replaying a level to reduce mistakes | Wants visible steps, undo, personal bests, and comparisons | FR-04, FR-07, FR-10, FR-13 |

Age, habits, quotes, and accessibility needs have not been invented. These sketches must become evidence-supported personas before claiming the highest problem-analysis band.

### 2.4 Competitor desk analysis

Analysis date: 21 October 2026. Method: review primary help/documentation pages; no hands-on mobile performance or accessibility evaluation is claimed.

| Product/source | Documented observation | Interpretation and decision |
|---|---|---|
| Sokoban Online, How to Play | Documents classic single-crate pushing, no pulling, goal completion, and keyboard undo/reset/pause | Adopt familiar rules and expose equivalent visible touch controls: FR-02–FR-06 |
| Sokoban Online, Getting Started | Permits guest play but says guest scores are not counted | Use anonymous backend identity for score submission without asking for email: FR-11–FR-13 |
| Skladnik, KDE Handbook | Describes recovering an impossible crate arrangement using undo | Make undo prominent and explain deadlocks: FR-04, FR-15 |

Sources: [Sokoban Online controls and rules](https://www.sokobanonline.com/help/how-to-play), [guest behavior](https://www.sokobanonline.com/help/getting-started), and [Skladnik handbook](https://docs.kde.org/trunk_kf6/en/skladnik/skladnik/skladnik.pdf). These observations inform requirements; they are not evidence that interviewees want those features. Features beyond this small project, such as level editors or modern puzzle objects, are excluded.

## 3. Functional requirements and acceptance criteria

Every row is a normative requirement. AC identifiers also identify manual acceptance test cases in section 10. Should requirements remain in the acceptance baseline; Could requirements are optional and may be omitted without changing Must completeness.

| ID | Priority | Requirement | Given–When–Then acceptance criterion |
|---|---|---|---|
| FR-01 | Must | Choose any of five packaged levels | AC-01: Given a first launch in airplane mode, when Play opens level selection, then L01–L05 are enabled and selecting any level loads its initial board without authentication. |
| FR-02 | Must | Move the player and reject wall input | AC-02: Given an active board, when one direction is tapped, then the player moves one cell if traversable; a wall or out-of-board input preserves board, history, and steps and shows blocked feedback. |
| FR-03 | Must | Push exactly one crate legally | AC-03: Given a crate adjacent to the player, when the player moves toward it, then both move one cell only if the cell beyond is traversable and crate-free; two adjacent crates and wall-backed crates remain unchanged. |
| FR-04 | Must | Undo without lowering score cost | AC-04: Given a nonempty history, when Undo is selected, then the preceding player/crate state is restored, history loses one entry, steps increase by one, and time is not reduced; Undo is disabled when history is empty. |
| FR-05 | Must | Restart with confirmation | AC-05: Given an active attempt, when Restart is selected, then play pauses for confirmation; Cancel retains its state and Confirm resets board, history, steps, and elapsed time using a new attempt ID. |
| FR-06 | Must | Pause, background, and resume safely | AC-06: Given active play, when Pause or app background occurs, then inputs and active timer stop; Resume continues the same board and counter without counting the paused interval. |
| FR-07 | Must | Display action count and active time | AC-07: Given steps=0, when a valid move, blocked move, then valid undo occur, then displayed steps are 1, 1, and 2 respectively; elapsed time advances only while active. |
| FR-08 | Must | Preserve one unfinished attempt locally | AC-08: Given a saved nontrivial attempt, when the app is reopened and Continue is chosen, then level/version, positions, history, steps, and elapsed time are restored and play resumes from pause; no save disables Continue. |
| FR-09 | Must | Support full offline gameplay | AC-09: Given first launch with no network, when any level is played, paused, restarted, completed, or resumed, then those operations remain available and completion results are stored locally. |
| FR-10 | Must | Detect completion and retain personal best | AC-10: Given one or more crates not on goals, when the last crate reaches its goal, then one completion is recorded, time/inputs freeze, the unfinished save is cleared, and best steps/time update only if improved. |
| FR-11 | Must | Create a guest identity without a sign-up screen | AC-11: Given no online session, when a pending result is ready and network is available, then anonymous authentication creates a guest profile automatically; failure preserves the result and does not block gameplay. |
| FR-12 | Must | Submit/retry results without duplicates | AC-12: Given one persisted pending UUID, when sending fails and the same result is retried, then it retains that UUID; a duplicate successful server receipt creates no second record, and the local item becomes synced only after acknowledgement. |
| FR-13 | Must | Show per-level guest leaderboard | AC-13: Given a selected level/version with results, when the leaderboard loads, then at most 20 best-per-guest entries appear in the specified deterministic order; changing level never shows another level's entries as current. |
| FR-14 | Must | Explain leaderboard and submission states | AC-14: Given loading, zero results, a request failure, or no network, when the relevant screen is shown, then it presents an explicit state with retry/navigation; cached data is labeled with level and last-updated time. |
| FR-15 | Must | Teach rules and recovery | AC-15: Given a new player, when How to Play is opened, then it explains four directions, pushing versus pulling, goal symbols, completion, undo, and restart; closing returns to Home. |
| FR-16 | Should | Offer controllable sound | AC-16: Given sound is enabled, when a valid push occurs, then a short effect plays; disabling sound persists across restart and suppresses effects; background and pause stop playback. |
| FR-17 | Could | Optional push haptic feedback | AC-17: Given haptics are implemented and enabled, when a valid crate push occurs, then one short haptic pulse occurs; blocked moves and background produce none. |

Out of scope for this release: multiplayer, combat, chat, email/social login, cross-device recovery, ads, purchases, procedural maps, map editor, solver hints, and the reference image's red line. Changing these boundaries requires change control.

## 4. Use cases and user flows

The primary actor is the Player. Supabase Auth and the Score Service are supporting system actors; the local store is an internal component. Use cases below cover all Must/Should requirements.

![Use case diagram](assets/use-cases.svg)

### UC-01 — Choose and start a level

Actor: Player. Preconditions: app initialized; bundled catalogue validated. Trigger: Play. Main flow: Home → Select Level → choose L01–L05 → instantiate initial GameSession → persist it → show active Gameplay. Postcondition: a new attempt is playable offline. Alternative: choosing a different level while an unfinished attempt exists asks before replacing the one save; Cancel preserves it. Failure: malformed bundled content shows a recoverable level error and returns to selection; this is a packaging defect to catch before release. Requirements: FR-01, FR-09.

### UC-02 — Play and finish

Actor: Player. Preconditions: active session. Trigger: directional tap. Main flow: ViewModel requests pure-rule validation; blocked input shows feedback without mutation; valid input snapshots the preceding board, updates positions, increments steps, persists, and redraws. If all crates are on goals, atomically save result/progress/outbox and clear unfinished state; show Completion. Alternatives: non-goal corners may cause a deadlock; Player can invoke UC-03. Failures: local save failure pauses play with Retry rather than falsely claiming progress was saved. Requirements: FR-02, FR-03, FR-07, FR-09, FR-10.

### UC-03 — Recover from a mistake

Actor: Player. Preconditions: active or paused unfinished attempt. Trigger: Undo or Restart. Undo pops one prior board snapshot, increments total steps, preserves elapsed time, and saves. Restart opens confirmation; Confirm creates a fresh attempt, Cancel resumes the prior state. Alternatives: Undo is disabled with no history. Postcondition: restored or initial board, never a negative counter. Requirements: FR-04, FR-05.

### UC-04 — Pause, leave, and continue

Actor: Player / OS lifecycle event. Preconditions: unfinished attempt. Trigger: Pause, Home, app background, or reopening. Main flow: flush active time and state, stop clock/audio/animation, show Pause or return Home. Continue restores and validates the save before resuming. Alternatives: no save disables Continue; replacing another attempt requires confirmation. Failure: incompatible/corrupt save offers Discard and Select Level, preserves bests/outbox, and explains that this attempt cannot resume. Requirements: FR-06, FR-08, FR-09.

### UC-05 — Publish a completed result

Actor: Player indirectly; supporting actors: Auth, Score Service. Preconditions: pending local completion. Triggers: app foreground startup, opening a leaderboard, or Retry. Main flow: obtain/refresh anonymous session; submit persisted UUID and score; backend validates ownership/payload and records receipt idempotently; acknowledge local row as synced. Alternatives: offline skips request; transient failure retains pending; failed authentication refresh is attempted once, then an explicit error remains. A non-recoverable validation/version error is marked rejected with explanation, not retried forever. Requirements: FR-11, FR-12, FR-14.

### UC-06 — View leaderboard

Actor: Player. Preconditions: none; reading rankings does not require a guest session. Trigger: Leaderboard and selected level. Main flow: show matching cached entries if present with an age label, request selected level/version, replace cache on success, and show top 20. Alternatives: empty result shows No results yet; offline with no cache shows an offline empty state; failure provides Retry. Cancel/ignore stale responses after changing level. Requirements: FR-13, FR-14.

### UC-07 — Read instructions and configure sound

Actor: Player. Trigger: How to Play or Settings from Home. Main flow: read rules; or change sound and persist preference locally. Postcondition: return to Home, preference retained without network. Sound stops when paused/backgrounded. Requirements: FR-15, FR-16.

![User flow and recovery paths](assets/user-flow.svg)

## 5. Non-functional requirements and mobile constraints

Targets below are acceptance commitments for A02. They are **not measurements of the A01 prototype**. Performance baseline: physical Android device, Android 10 or newer, at least 4 GB RAM, release build, exact device/OS/build recorded. Test both 640 x 360 dp and 800 x 450 dp landscape viewports, with appropriate system-bar insets.

| ID | Measurable requirement | Verification method |
|---|---|---|
| NFR-01 | Cold launch to usable Home <=3 s in at least 95% of 20 trials | Timed release-build launches; include failed/slow trials |
| NFR-02 | Input-to-visible-move <=100 ms in at least 95% of 100 valid inputs | Frame timestamps/profiling on the baseline device |
| NFR-03 | Selected leaderboard response rendered <=3 s in at least 95% of 20 Wi-Fi trials; client timeout 10 s | Record complete request-to-render time; do not silently exclude server cold starts |
| NFR-04 | All five boards and core local actions work on first launch in airplane mode | Fresh install offline walkthrough; verify persistent progress after restart |
| NFR-05 | No timer/audio/animation progression after background lifecycle handler; no periodic network polling or background sync | Lifecycle tests; 60-second background observation and network capture |
| NFR-06 | HTTPS only; tokens in OS-backed secure storage; no privileged backend secrets in repo/app | Config/repo/build inspection; verify secure-storage session adapter |
| NFR-07 | Writes bound to authenticated guest; rankings expose only public score fields; expired sessions cannot write | A02 authorization and cross-user integration tests |
| NFR-08 | No dangerous runtime permissions; network access only | Android manifest review and fresh-install permission walkthrough |
| NFR-09 | Touch areas >=48 x 48 dp; body contrast >=4.5:1; target/completed-crate shapes differ | Layout/contrast audit at smallest viewport; verify labels with TalkBack |
| NFR-10 | Landscape Android 10+; no clipped board or overlapping controls at both defined viewports | Screenshot/layout comparison with safe areas and 1.3x system text |
| NFR-11 | No repeated idle network requests; leaderboard payload <=50 KB for 20 rows | Network capture and serialized-response measurement |
| NFR-12 | Every acknowledged local action restores consistently; completion is atomic; duplicate sends create one receipt | Fault injection around SQLite transactions and API retry integration tests |

For a network failure, return control after timeout and preserve the result; never spin indefinitely. A local storage error must be visible, since uninterrupted play would imply untrue persistence. Larger accessibility text may scroll explanatory content; gameplay counters remain readable without hiding touch targets. Motion is a short transition, not essential information.

The OS may terminate a process without delivering a final lifecycle callback. Save active state after each acknowledged action; checkpoint active elapsed time every second while active. Unexpected termination may lose at most one second of unsaved timer time, but not the last acknowledged board/steps. Normal backgrounding flushes elapsed time immediately. Timer-only checkpoints do not require network.

## 6. System and in-app architecture

### 6.1 Technology choices and tradeoffs

Use Flutter/Dart for touch UI, grid layout, and short animations. A dedicated physics/game engine is unnecessary for a small turn-based board. Use ChangeNotifier ViewModels; keep deterministic game rules as pure Dart without Flutter, network, or SQLite dependencies. Flutter's architecture guide describes separating Views/ViewModels from Repositories/Services; this project adopts that structure with a small game-rule component rather than a large framework hierarchy.

Use SQLite for atomic local session/progress/outbox changes and Supabase for anonymous Auth plus PostgreSQL/RPC. Supabase avoids a separately operated application server. Use an OS-backed secure storage adapter for Auth session persistence rather than assuming the SDK's default persistence is sufficiently secure. Package JSON levels with the app, and pin package/SDK versions during A02 setup after a buildable toolchain is confirmed.

![Overall system architecture](assets/system-architecture.svg)

![In-app architecture and responsibilities](assets/app-architecture.svg)

### 6.2 Responsibilities and interfaces

| Component | Responsibility | Logical interface |
|---|---|---|
| GameView / MenuViews | Render state and emit user intent; no rule or SQL logic | onDirection, onUndo, onPause, onRetry |
| GameViewModel | Serialize input; maintain active/pause/completed state; coordinate timer and saves | start(level), move(direction), undo(), restart(), pause(), resume() |
| GameRules | Pure movement/push validation, board transition, solved check | tryMove(board, direction), isSolved(board) |
| SessionRepository | One save slot; transactionally persist/restore session and completion | loadSession(), saveSession(), completeAttempt() |
| ProgressRepository | Personal best comparison and completed flags | bestFor(levelVersion), recordResult() |
| ScoreRepository / ScoreViewModel | Outbox, ranking cache, submit lifecycle, selected-level request guard | retryPending(), leaderboard(levelVersion) |
| LevelService / LocalStore | Parse packaged levels; SQLite read/write transactions | readCatalogue(), transaction() |
| SupabaseService / SecureSessionStore | Auth refresh, RPC, secure token persistence; never implement game rules | ensureGuest(), submitScore(), getLeaderboard() |
| SettingsRepository | Local persisted sound setting, default enabled | loadSettings(), setSound(enabled) |

Do not process overlapping direction/undo intents while an action is being committed. Failed saves retain the last persisted board, pause inputs, and offer Retry. Start monotonic active time only after initial load completes. Timer ticks update state without re-running movement logic.

### 6.3 Sequence diagrams

![Move, save, undo, and completion](assets/sequence-play.svg)

![Save, lifecycle pause, and restore](assets/sequence-resume.svg)

![Guest authentication, idempotent submission, and rankings](assets/sequence-online.svg)

Sequences include blocked input, offline/auth/request failure, invalid saves, and duplicate success. A02 must preserve these behaviors; a changed storage/backend approach requires a documented rationale and corresponding updates.

## 7. Data model and persistence

![Logical data model with local and remote boundaries](assets/erd.svg)

### 7.1 Logical entities

| Entity | Key and essential fields | Location and relationship |
|---|---|---|
| Level | id, version, name, map, width, height; compound key (id, version) | Packaged JSON; remote immutable catalogue mirrors IDs/versions |
| GameSession | slot=1, attempt_id UUID, level_id/version, player [x,y], crates [[x,y]], history, total_actions >=0, elapsed_ms >=0, saved_at UTC, schema_version | SQLite; at most one unfinished session; references packaged Level |
| Progress | level_id/version, completed, best_steps, best_elapsed_ms | SQLite; one row per level/version; both best metrics come from the same attempt |
| GuestProfile | auth_user_id UUID, display_name, created_at UTC | Remote Auth user 1:1 guest profile; ID may be absent locally until first online send |
| ScoreSubmission | submission_id UUID, level_id/version, steps >=1, elapsed_ms >=0, status, attempt_id, last_error | SQLite outbox; one row per completed attempt; no token fields |
| ScoreReceipt | guest_id, submission_id, level_id/version, steps, elapsed_ms, received_at | Remote; unique (guest_id, submission_id); many receipts per guest/level |
| LeaderboardCache | level_id/version, fetched_at UTC, public rows JSON | SQLite; independent cache per level/version; show last-updated label |
| Settings | singleton key, sound_enabled boolean | SQLite; sound defaults true |

Undo history contains only prior player/crate positions, not copies of elapsed time or total actions. Undoing therefore cannot rewind score cost. Validate cells, crate count, level identity, and history against the packaged layout when restoring. A schema/level-version mismatch produces an explicit restart choice; progress and pending submissions remain separate and intact.

### 7.2 Example persisted session

```json
{
  "schema_version": 1,
  "slot": 1,
  "attempt_id": "10000000-0000-4000-8000-000000000001",
  "level_id": "L01",
  "level_version": 1,
  "player": [3, 2],
  "crates": [[4, 2]],
  "history": [{"player": [2, 2], "crates": [[3, 2]]}],
  "total_actions": 1,
  "elapsed_ms": 1200,
  "saved_at": "2026-10-21T08:00:00Z"
}
```

### 7.3 Transactions, identity, and retention

On a valid move/undo, commit updated positions, history, counters, and current elapsed time together before acknowledging the action. At completion, commit progress comparison, one outbox item, and save-slot removal in one transaction. Generate the submission UUID once at this point, not on each retry. Compare score pairs lexicographically; do not combine best steps from one attempt with best time from another.

Obtain anonymous Auth only when an online write is necessary. Bind a pending item to the guest ID before its first send so retries cannot silently move it to another identity. A refresh failure preserves the binding and pending state. If the guest identity is irrecoverably lost, explain that old online results cannot be recovered; require explicit user acknowledgement before rebinding unsent data to a new guest. Cross-device identity recovery is out of scope.

Persist local completed/best progress until app data is cleared; retain cached rankings until replaced. Remove acknowledged outbox payloads after recording sync status for the completion view. Anonymous cloud identity and scores may outlive an uninstall; data-clearing is not represented as cloud deletion. The course demo retains backend results until the project owner resets the project after assessment. No personal name/email is needed.

No automatic network background worker is required. A retry trigger processes the finite pending queue with one request at a time; retain failures and avoid an immediate retry loop. Restored network connectivity alone need not trigger sending until the next specified foreground action.

## 8. API contract and security

### 8.1 Transport and authentication

The machine-readable design contract is `docs/api/openapi.json`. Replace the example project URL with the actual Supabase project at A02. No live endpoint or credential is shipped here. Use HTTPS and the project publishable API key. This key is intentionally client-visible; it is not a substitute for authorization. Never ship the service-role/secret key. Scope grants and RLS separately.

Anonymous sign-in uses `POST /auth/v1/signup` with `{}` through the Supabase SDK. Auth returns a session; persist tokens using the secure adapter and never log them. Reading `get_leaderboard` is allowed to anonymous public clients; `submit_score` requires a valid authenticated guest JWT. A user created through anonymous Auth uses the authenticated role, not the unauthenticated `anon` role. Auth provider errors use Supabase's documented format and are mapped to application auth errors.

### 8.2 Submit a result

`POST /rest/v1/rpc/submit_score` — headers: apikey, Authorization: Bearer access-token, Content-Type: application/json. The server derives guest_id from the JWT; no caller-controlled guest_id is accepted.

```json
{
  "p_submission_id": "20000000-0000-4000-8000-000000000001",
  "p_level_id": "L01",
  "p_level_version": 1,
  "p_steps": 2,
  "p_elapsed_ms": 3200
}
```

Success: HTTP 200, returned as a single JSON object:

```json
{
  "submission_id": "20000000-0000-4000-8000-000000000001",
  "status": "accepted",
  "is_personal_best": true,
  "received_at": "2026-10-21T08:00:04Z"
}
```

Repeated same guest/UUID and identical payload returns the original receipt with status `duplicate`, preserving received_at. A duplicate's best flag means whether that receipt is the guest's best at the time of this response. Same key with different payload returns HTTP 409 IDEMPOTENCY_CONFLICT. Another guest cannot inspect/reuse this guest's receipt. Validate known level/version, integer steps in 1..100000, and integer elapsed_ms in 0..86400000; these caps are an explicit submission policy, not a time limit on local play. Longer attempts stay locally completed but are rejected for online submission with an explanation.

Implement receipt uniqueness and best selection transactionally. An unchanged old version remains queryable if retained in the remote immutable catalogue. Unknown versions are rejected rather than silently ranked with another layout. Server checks validate payload/ownership, not that the moves truly solved a board; anti-cheat replay is outside this educational leaderboard's scope.

### 8.3 Read rankings

`POST /rest/v1/rpc/get_leaderboard` — apikey and Content-Type headers. Body: `{"p_level_id":"L01","p_level_version":1}`. Public response contains no auth identifiers or email. Return a single object with a fixed limit of 20; no pagination is needed.

```json
{
  "level_id": "L01",
  "level_version": 1,
  "generated_at": "2026-10-21T08:00:05Z",
  "entries": [
    {"rank": 1, "display_name": "Guest-7F2A90C1D4", "steps": 2, "elapsed_ms": 3200}
  ]
}
```

Display names are server-generated from a short guest-ID prefix; any display-name collision has no identity/ownership meaning. Return `entries: []` for a known level with no results. Reject an unknown level/version as 404. On level change, update screen context immediately and cancel or discard obsolete requests; never relabel a previous level's rows as current.

### 8.4 Error contract and permission design

RPC errors follow the PostgREST shape below. Custom HTTP status errors can be raised with PTxxx SQLSTATE codes; the UI uses the stable message code, not a fragile substring match on database prose.

```json
{
  "code": "PT409",
  "message": "IDEMPOTENCY_CONFLICT",
  "details": "The same submission ID was used with different score data.",
  "hint": null
}
```

| HTTP/client state | Message/code | Required behavior |
|---|---|---|
| 400 | INVALID_ARGUMENT / PT400 | Mark result rejected with explanation; do not loop |
| 401 | AUTH_REQUIRED / PT401 or gateway auth error | Refresh once; preserve pending/binding on failure |
| 403 | FORBIDDEN / PT403 or SQLSTATE 42501 | Show permission error; retain local result for support/retry after correction |
| 404 | LEVEL_NOT_FOUND / PT404 | Reject the mismatched version; preserve personal progress |
| 409 | IDEMPOTENCY_CONFLICT / PT409 | Stop automatic retries; record diagnosable error |
| 429 | RATE_LIMITED | Retain pending; honor Retry-After if supplied; later manual/foreground retry |
| 5xx | Temporary provider/server error | Retain pending and allow Retry |
| Client timeout/offline | No HTTP response | Do not invent a server receipt; retry using the same UUID |

RLS denies direct public reads/writes of profiles and score receipts. Revoke direct table mutation and default PUBLIC function execution. Grant only the required RPC execute rights. A narrowly scoped database function may use SECURITY DEFINER with an empty search_path and schema-qualified objects; submit must explicitly require auth.uid(), insert only that identity, and accept no identity override. The public ranking function returns only allowlisted fields. Integration tests must exercise direct-table access, anonymous writes, cross-guest access, and receipt races. Rate-limit behavior belongs to the deployed provider; this document does not claim a custom anti-abuse system already exists.

## 9. UI/UX and clickable prototype

### 9.1 Visual system and accessibility

Design assets use a 1280 x 720 canvas at 2x for a baseline 640 x 360 dp viewport. Interactive buttons are at least 96 x 96 design pixels (48 dp at baseline). Board cells scale uniformly to fit their fixed area without becoming controls. Gameplay stays separate from the left D-pad and right action rail; system insets must be applied in A02.

| Token | Value | Use |
|---|---|---|
| Ink | #173B32 | Body and heading text on light surfaces |
| Forest | #164A3A | Main actions and navigation |
| Paper | #FFF8E7 | Cards and primary button text |
| Meadow | #B4CC75 | Board floor |
| Gold | #F4C766 | Goal accents; pair with dark text |
| Muted ink | #486156 | Secondary text on paper |
| Alert | #8A3028 | Error text on paper |
| Type | Inter Regular/Bold in Figma; sans-serif locally | 28 px body, 40–62 px headings on the 2x canvas |

Goal tiles show a ring/diamond marker; a crate on goal includes a check mark. The player uses a distinct hat/body silhouette. Do not rely on color or audio alone. Every production control receives a semantic label, and Steps/Time/status updates must be available to assistive technology without excessively announcing timer ticks. Sound is supplementary. The prototype is a visual/navigation design, not proof of TalkBack compatibility.

### 9.2 Screen inventory and state coverage

| Screen ID | Purpose | Required states |
|---|---|---|
| SCR-01 | Home | New player, Continue available |
| SCR-02 | Select Level | Five enabled cards, completed badge/best, replace-save confirmation |
| SCR-03 | How to Play | Core rules, goal symbols, deadlock recovery |
| SCR-04 | Gameplay | Initial, valid push, blocked action, undo, restored session, other level layouts, local-save error |
| SCR-05 | Pause/confirmation | Resume, Home, Restart confirm/cancel, corrupt-save recovery |
| SCR-06 | Completion | Pending, synced, submission error/retry |
| SCR-07 | Leaderboard | Loading, populated, level changed, empty, request error, offline cached, offline without cache |
| SCR-08 | Settings | Sound on/off, saved preference |

All exported frames are embedded in the PDF appendix. IDs have suffixes for variations; the hotspot manifest records actual navigation. Representative screens:

![Home — start a short forest puzzle](../prototype/screens/SCR-01.svg)

![Level selection — all five levels available](../prototype/screens/SCR-02.svg)

![Gameplay — separated board and touch controls](../prototype/screens/SCR-04.svg)

![Completion — local result with sync status](../prototype/screens/SCR-06.svg)

![Leaderboard — level-specific scores](../prototype/screens/SCR-07.svg)

### 9.3 Prototype behavior and limitations

The Figma package creates editable shapes/text and linked frames. The local `prototype/index.html` offers the same screen graph for immediate review and works by opening the file directly. It uses scripted navigation and mock data; it is not the A02 game or a live backend. The primary demonstrated run is L01: Right → Right → Completion; separate branches show wall feedback, undo, pause, cancel/confirm restart, and restoring a saved attempt. The remaining maps are shown as previews, not simulated full playthroughs.

Design review entry points include a state menu so reviewers can inspect every error/offline variation without waiting for a real failure. This review menu belongs to the preview shell, not the shipped game UI. Functional gameplay and automatic state transitions are A02 work.

**Figma prototype URL:** PENDING — importer prepared; Figma runtime review and viewer-accessible share link required.

If pending, follow `prototype/figma/README.md`, run the importer in a Figma Design file, inspect interactions/fonts, and set a viewer-accessible URL in `prototype/links.json`. Regenerate the PDF afterward. A local SVG export is not described as a published Figma prototype.

### 9.4 Usability plan

Run three consented sessions after import. Ask participants to start a level, explain symbols, push/undo, pause/resume, cancel restart, view rankings, recover an offline send, and mute sound. Record task success, assistance, duration, errors, and comments in `docs/research/usability.csv`. Log each accepted design change. Current status: **no sessions conducted**, no success-rate claims. At least the navigation and terminology issues found must be resolved or explicitly accepted before final approval.

## 10. Traceability and verification

### 10.1 Requirement traceability matrix

Requirement-to-use-case-to-screen-to-component-to-test links are normative. CSV copies are generated for filtering; this table remains part of the consolidated document.

| Requirement | Use case | Screen | Component | Test |
|---|---|---|---|---|
| FR-01 | UC-01 | SCR-01, SCR-02, SCR-04 | GameViewModel, LevelService | AC-01 |
| FR-02 | UC-02 | SCR-04 | GameRules, GameViewModel | AC-02 |
| FR-03 | UC-02 | SCR-04 | GameRules, GameViewModel | AC-03 |
| FR-04 | UC-03 | SCR-04 | GameRules, SessionRepository | AC-04 |
| FR-05 | UC-03 | SCR-04, SCR-05 | GameViewModel, SessionRepository | AC-05 |
| FR-06 | UC-04 | SCR-04, SCR-05 | GameViewModel, SessionRepository | AC-06 |
| FR-07 | UC-02 | SCR-04, SCR-06 | GameViewModel | AC-07 |
| FR-08 | UC-04 | SCR-01, SCR-04, SCR-05 | SessionRepository | AC-08 |
| FR-09 | UC-01, UC-02, UC-04 | SCR-01, SCR-02, SCR-04, SCR-06 | LevelService, LocalStore | AC-09 |
| FR-10 | UC-02 | SCR-02, SCR-06 | GameRules, ProgressRepository, SessionRepository | AC-10 |
| FR-11 | UC-05 | SCR-06 | SupabaseService, SecureSessionStore | AC-11 |
| FR-12 | UC-05 | SCR-06 | ScoreRepository, SupabaseService | AC-12 |
| FR-13 | UC-06 | SCR-07 | ScoreRepository, ScoreViewModel | AC-13 |
| FR-14 | UC-05, UC-06 | SCR-06, SCR-07 | ScoreViewModel, SupabaseService | AC-14 |
| FR-15 | UC-07 | SCR-01, SCR-03 | MenuViews | AC-15 |
| FR-16 | UC-07 | SCR-08 | SettingsRepository, GameViewModel | AC-16 |
| FR-17 | UC-02 | SCR-04 | GameViewModel | AC-17 |

Non-functional requirements also have explicit verification ownership. Their tests are planned for the implementation phase, not marked passed by this document.

| NFR | Use case | Screen | Component | Test |
|---|---|---|---|---|
| NFR-01 | UC-01 | SCR-01 | MenuViews, LevelService | VF-01 Cold launch |
| NFR-02 | UC-02 | SCR-04 | GameViewModel, GameRules | VF-02 Input latency |
| NFR-03 | UC-06 | SCR-07 | ScoreRepository, SupabaseService | VF-03 Network timings |
| NFR-04 | UC-01, UC-02, UC-04 | SCR-02, SCR-04 | LocalStore, SessionRepository | VF-04 First-launch offline |
| NFR-05 | UC-04 | SCR-05 | GameViewModel | VF-05 Lifecycle observation |
| NFR-06 | UC-05 | SCR-06 | SecureSessionStore, SupabaseService | VF-06 Secret/storage audit |
| NFR-07 | UC-05, UC-06 | SCR-06, SCR-07 | SupabaseService | VF-07 Authorization integration |
| NFR-08 | UC-01 | SCR-01 | Android manifest | VF-08 Permission walkthrough |
| NFR-09 | UC-01, UC-02, UC-07 | SCR-01, SCR-03, SCR-04, SCR-08 | GameView, MenuViews | VF-09 Accessibility audit |
| NFR-10 | UC-01, UC-02 | SCR-02, SCR-04 | GameView, MenuViews | VF-10 Viewport and text-size audit |
| NFR-11 | UC-06 | SCR-07 | ScoreRepository | VF-11 Network capture |
| NFR-12 | UC-02, UC-04, UC-05 | SCR-04, SCR-06 | LocalStore, SessionRepository, ScoreRepository | VF-12 Fault injection |

### 10.2 Test design and expected scenarios

The acceptance table supplies Given/When/Then for AC-01–AC-17. `docs/test-cases.csv` records preconditions, action, expected result, phase, and execution status; actual A02 results are pending. Additional scenarios:

| ID | Scenario | Expected result | Phase/status |
|---|---|---|---|
| DV-01 | Replay all five reference solutions | No blocked steps; every crate on goal at the final step | A01 automated design check |
| DV-02 | Independent shortest-path search | All maps solvable; shortest action counts increase across the catalogue | A01 automated design check |
| DV-03 | Traceability, frame links, reachability, target sizes, sample API shape | No missing Must/Should references; every frame reachable in review graph; intended target dimensions valid | A01 automated static check |
| DV-04 | PDF structural checks and embedded vector pages | Valid page tree/xref and expected diagrams/screens/text; no dependency on remote fonts/images | A01 automated structural check; visual review still needed |
| UT-01 | Pure rule fixture: floor/wall/crate-goal/double-crate/wall-backed crate | Correct state, no mutation for blocked input, goal under crate retained | A02 not run |
| UT-02 | Undo stack and monotonic action counter | Empty history disabled; snapshot exact; undo does not decrement score/time | A02 not run |
| UT-03 | Best-pair comparison and complete-attempt transaction | Best steps/time remain one pair; one outbox row per attempt | A02 not run |
| IT-01 | Termination after move and around completion commit | Restore last acknowledged board or exactly one complete result; no half-transaction | A02 not run |
| IT-02 | Timeout after server commit, then retry | Same UUID returns duplicate receipt; one best row per guest | A02 not run |
| IT-03 | Invalid arguments/auth, forbidden direct-table access, cross-guest access | Errors match contract; no unauthorized result ownership change | A02 not run |
| IT-04 | Switch levels while first ranking request is slow | Late response never replaces selected-level context | A02 not run |
| MT-01 | Corrupt save or unknown level version | Explain issue; explicit discard choice; preserve progress/outbox | A02 not run |
| MT-02 | 640 x 360 and 800 x 450 dp, 1.3x text, safe insets | Controls remain reachable; no board/control overlap | A02 not run |
| UX-01 | Three participant prototype sessions | Record real task outcomes and resolve design findings | A01 not conducted |

For every NFR, run the method in section 5 and record device/network/build, sample count, raw timings, percentile calculation, pass/fail, and evidence path. Do not mark performance or security as passed because a diagram or static prototype exists. Static target sizes do not prove production accessibility.

## 11. Delivery, change control, and A02 handoff

### 11.1 Working schedule and ownership

The schedule is seven relative workdays, not a promised calendar deadline. Days 1–2: Member A conducts interviews and reviews requirements; Member B reviews competitors and maps. Day 3: A reviews architecture/sequences while B reviews flows. Days 4–5: A reviews API/data/NFRs/tests while B imports/reviews Figma. Day 6: A audits traceability while B runs usability sessions. Day 7: both consolidate evidence, approve the baseline, and verify sharing. Actual names, Git commits, and contribution notes must replace placeholders.

### 11.2 Baseline and change log

Current status is v1.0-draft. Final v1.0 requires both members' approval after real research and prototype verification. `docs/change-log.csv` records date, rationale, affected requirements/screens/components/tests, author, and reviewer. Any A02 departure from this baseline must be recorded and traced before accepting the new behavior. Preserve actual contribution history and use branches/PRs as work occurs; no retroactive fabricated history.

### 11.3 Submission gate

- All Must/Should acceptance criteria have complete trace links and matching design states.
- The consolidated PDF includes diagrams, mockups, research evidence/findings, and a working viewer-accessible Figma prototype URL.
- Three to five interviews and three usability sessions have genuine evidence, or the submission transparently acknowledges incompleteness and its grading impact.
- Both personas have evidence citations; sources, AI usage, team contributions, and open issues are accurately declared.
- Five maps pass replay/search validation; source files regenerate deliverables without secrets or network.
- Both members can explain the document and their future implementation responsibilities.

### 11.4 A02 carry-forward requirements

Implement the agreed MVVM separation, real Supabase integration and failure handling, secure session storage, core unit tests, manual AC/NFR results, and UI state coverage. Produce a preliminary build for the ungraded mid-term review. Maintain a README for a fresh checkout, configuration placeholders, schema/setup instructions, exact build commands, and installable APK; the rubric caps A02 at 40/100 if it cannot build/run from the repo. Prepare a demo that includes offline play, undo, resume, completion, online sync/retry, and rankings, with both members able to explain their own code. Respect the actual course AI-use policy and late-submission rules; confirm any provisional policy wording with the assignment brief.

## 12. Evidence, attribution, and declarations

### 12.1 Evidence register

| Evidence | Artifact | Current status |
|---|---|---|
| Desk analysis | Section 2.4 and primary source references | Completed as document review; not hands-on testing |
| Interview records P01–P05 | docs/research/interviews.csv | Templates only; sessions not conducted |
| Research findings | docs/research/findings.csv | Empty; populate from actual observations |
| Personas PP-01/PP-02 | Section 2.3 | Hypotheses only; evidence pending |
| Usability U01–U03 | docs/research/usability.csv | Templates only; sessions not conducted |
| Design verification | deliverables/validation-report.md | Generated by the supplied validator; not app testing |
| Figma share/runtime check | prototype/links.json | Pending until explicitly recorded |
| Team approval/contributions | project-step.md and change log | Real member names/reviews pending |

### 12.2 Interview and usability forms

Interview record fields: participant ID, actual session date, consent to notes, recent-play context, usual session length, network experience, recovery expectations, ranking preference, accessibility observations, anonymized notes, and status. Questions: describe recent mobile play; length of breaks; experience losing network; expected pushing behavior; recovering mistakes/closing; use of bests/rankings; readability/control problems; what is unclear after seeing the concept.

Finding record fields: finding ID, evidence type/source or participant ID, observation, interpretation, affected requirement IDs, decision, status. Keep evidence separate from design inference.

Usability record fields: participant ID, session date, consent, tool/version, task ID, success, assistance, duration, observed issue, severity, anonymized comment, and change-log ID. Tasks cover start, symbols, first push, undo, pause/resume, cancel restart, rankings, offline retry, and sound. Do not collect names or recordings without explicit consent; keep raw identity/recording material outside the public repository.

### 12.3 Asset register and reference boundary

All included forest, character, crate, icon, diagram, and screen artwork is original code-generated vector design for this package. The five maps are original small teaching designs. No source-game art, screenshots, audio, or levels are redistributed. The user-provided screenshot is a visual reference only; its copyright/license is unverified. The unavailable URL `https://www.gpsuu.com/game/33740.html` is recorded for provenance, not used as evidence of gameplay rules.

Generated PDF uses built-in Helvetica/Courier; SVG/local preview uses system sans-serif. The Figma importer requests Inter, available in Figma; actual font availability must be checked when running it. No sound files are included; A02 must add original or appropriately licensed effects and record their licenses.

### 12.4 AI-use declaration and contribution record

Draft declaration: An OpenAI coding assistant helped structure this specification, author acceptance criteria/API design, generate original vector screens and diagrams, create the Figma import package, and write document/level verification scripts. Generated content requires team review. AI did not conduct participant research, create real participant quotes, run the Flutter application, deploy Supabase, or certify accessibility/performance. The team must update this declaration to reflect actual use and confirm compliance with the assignment brief.

Member A actual contribution: **pending name and verified work log**. Member B actual contribution: **pending name and verified work log**. Both members' document approval: **pending**. Do not attribute AI-authored work to completed human contributions without review.

### 12.5 Primary technical references

- [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide): Views, ViewModels, Repositories, and Services.
- [Flutter offline-first guidance](https://docs.flutter.dev/app-architecture/design-patterns/offline-first): separating local/remote data access.
- [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms): check SDK/platform compatibility when pinning A02 toolchain.
- [Supabase anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous): anonymous users and session behavior.
- [Supabase row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security): authorization boundaries.
- [PostgREST errors](https://docs.postgrest.org/en/stable/references/errors.html): error envelope and custom status codes.
- [Figma prototype reactions](https://developers.figma.com/docs/plugins/api/properties/nodes-reactions/): frame navigation with setReactionsAsync.
- [Material accessible design](https://m3.material.io/foundations/accessible-design/overview): accessibility design review reference.

Terms: **A01** specification assignment; **A02** implementation assignment; **AC** acceptance criterion; **MVVM** Model–View–ViewModel; **RPC** remote procedure call; **RLS** row-level security; **outbox** locally persisted pending operations; **idempotency** safe repetition of one submission without an extra receipt; **proto-persona** an unvalidated user hypothesis; **dp** Android density-independent pixel.

## Appendix A — Full screen and state gallery

### SCR-01 — Home - first visit

![Home - first visit](../prototype/screens/SCR-01.svg)

### SCR-01r — Home - saved game

![Home - saved game](../prototype/screens/SCR-01r.svg)

### SCR-02 — Select Level

![Select Level](../prototype/screens/SCR-02.svg)

### SCR-03 — How to Play

![How to Play](../prototype/screens/SCR-03.svg)

### SCR-04 — Gameplay - initial

![Gameplay - initial](../prototype/screens/SCR-04.svg)

### SCR-04p — Gameplay - first push

![Gameplay - first push](../prototype/screens/SCR-04p.svg)

### SCR-04w — Gameplay - beside a wall

![Gameplay - beside a wall](../prototype/screens/SCR-04w.svg)

### SCR-04b — Gameplay - blocked at wall

![Gameplay - blocked at wall](../prototype/screens/SCR-04b.svg)

### SCR-04u — Gameplay - undo restores board

![Gameplay - undo restores board](../prototype/screens/SCR-04u.svg)

### SCR-04q — Gameplay - push after undo

![Gameplay - push after undo](../prototype/screens/SCR-04q.svg)

### SCR-04r — Gameplay - restored save

![Gameplay - restored save](../prototype/screens/SCR-04r.svg)

### SCR-04L2 — Gameplay - Level 2 layout preview

![Gameplay - Level 2 layout preview](../prototype/screens/SCR-04L2.svg)

### SCR-04L3 — Gameplay - Level 3 layout preview

![Gameplay - Level 3 layout preview](../prototype/screens/SCR-04L3.svg)

### SCR-04L4 — Gameplay - Level 4 layout preview

![Gameplay - Level 4 layout preview](../prototype/screens/SCR-04L4.svg)

### SCR-04L5 — Gameplay - Level 5 layout preview

![Gameplay - Level 5 layout preview](../prototype/screens/SCR-04L5.svg)

### SCR-05 — Take a breath

![Take a breath](../prototype/screens/SCR-05.svg)

### SCR-05i — Take a breath

![Take a breath](../prototype/screens/SCR-05i.svg)

### SCR-05c — Restart this level?

![Restart this level?](../prototype/screens/SCR-05c.svg)

### SCR-05ci — Restart this level?

![Restart this level?](../prototype/screens/SCR-05ci.svg)

### SCR-05x — Saved game unavailable

![Saved game unavailable](../prototype/screens/SCR-05x.svg)

### SCR-05s — Could not save

![Could not save](../prototype/screens/SCR-05s.svg)

### SCR-02c — Replace saved attempt?

![Replace saved attempt?](../prototype/screens/SCR-02c.svg)

### SCR-06 — Completion - pending

![Completion - pending](../prototype/screens/SCR-06.svg)

### SCR-06s — Completion - synced

![Completion - synced](../prototype/screens/SCR-06s.svg)

### SCR-06e — Completion - error

![Completion - error](../prototype/screens/SCR-06e.svg)

### SCR-06u — Completion - after undo

![Completion - after undo](../prototype/screens/SCR-06u.svg)

### SCR-07 — Leaderboard - populated

![Leaderboard - populated](../prototype/screens/SCR-07.svg)

### SCR-07l — Leaderboard - loading

![Leaderboard - loading](../prototype/screens/SCR-07l.svg)

### SCR-07n — Leaderboard - empty

![Leaderboard - empty](../prototype/screens/SCR-07n.svg)

### SCR-07e — Leaderboard - error

![Leaderboard - error](../prototype/screens/SCR-07e.svg)

### SCR-07o — Leaderboard - offline cached

![Leaderboard - offline cached](../prototype/screens/SCR-07o.svg)

### SCR-07z — Leaderboard - offline no cache

![Leaderboard - offline no cache](../prototype/screens/SCR-07z.svg)

### SCR-072 — Leaderboard - Level 2

![Leaderboard - Level 2](../prototype/screens/SCR-072.svg)

### SCR-073 — Leaderboard - Level 3

![Leaderboard - Level 3](../prototype/screens/SCR-073.svg)

### SCR-074 — Leaderboard - Level 4

![Leaderboard - Level 4](../prototype/screens/SCR-074.svg)

### SCR-075 — Leaderboard - Level 5

![Leaderboard - Level 5](../prototype/screens/SCR-075.svg)

### SCR-08 — Settings - sound on

![Settings - sound on](../prototype/screens/SCR-08.svg)

### SCR-08m — Settings - sound off

![Settings - sound off](../prototype/screens/SCR-08m.svg)

## Appendix B — Machine-readable contract

The complete JSON contract is included below so that the consolidated document remains self-contained. API host values are placeholders and no deployment is claimed.

```json
{
  "openapi": "3.0.3",
  "info": {
    "title": "Forest Sokoban A01 API Design",
    "version": "1.0.0-draft",
    "description": "Design only. HTTPS Supabase Auth plus PostgREST JSON-object RPCs. No live project or credentials included. Rankings use steps, elapsed_ms, received_at, then submission UUID. Input score caps affect online eligibility, not offline gameplay."
  },
  "servers": [
    {
      "url": "https://PROJECT_REF.supabase.co",
      "description": "Replace at A02 setup; placeholder, not deployed"
    }
  ],
  "paths": {
    "/auth/v1/signup": {
      "post": {
        "operationId": "createAnonymousGuest",
        "summary": "SDK-managed anonymous sign-in",
        "security": [
          {
            "ProjectKey": []
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "maxProperties": 0
              },
              "example": {}
            }
          }
        },
        "responses": {
          "200": {
            "description": "Supabase session; persist through an OS-secure adapter",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/AuthSession"
                }
              }
            }
          },
          "default": {
            "description": "Supabase Auth provider error; normalize to an auth error, not an RPC error"
          }
        }
      }
    },
    "/rest/v1/rpc/submit_score": {
      "post": {
        "operationId": "submitScore",
        "summary": "Submit one completed attempt idempotently",
        "description": "Requires Auth JWT. Derive ownership from auth.uid(); unique (guest_id, submission_id). Same payload returns original receipt; changed payload under same ID raises PT409. Return a jsonb object rather than a set-returning row array.",
        "security": [
          {
            "ProjectKey": [],
            "GuestJWT": []
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/ScoreRequest"
              },
              "example": {
                "p_submission_id": "20000000-0000-4000-8000-000000000001",
                "p_level_id": "L01",
                "p_level_version": 1,
                "p_steps": 2,
                "p_elapsed_ms": 3200
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Accepted or idempotent duplicate; received_at is stable",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/ScoreReceipt"
                },
                "example": {
                  "submission_id": "20000000-0000-4000-8000-000000000001",
                  "status": "accepted",
                  "is_personal_best": true,
                  "received_at": "2026-10-21T08:00:04Z"
                }
              }
            }
          },
          "400": {
            "description": "INVALID_ARGUMENT / PT400",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "401": {
            "description": "AUTH_REQUIRED / PT401; gateway auth codes may differ",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "403": {
            "description": "FORBIDDEN / PT403 or 42501",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "404": {
            "description": "LEVEL_NOT_FOUND / PT404",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "409": {
            "description": "IDEMPOTENCY_CONFLICT / PT409",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "429": {
            "description": "Provider rate limit; inspect Retry-After",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "500": {
            "description": "Temporary server error; preserve local result",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          }
        }
      }
    },
    "/rest/v1/rpc/get_leaderboard": {
      "post": {
        "operationId": "getLeaderboard",
        "summary": "Public top 20 for one known level/version",
        "description": "No auth user IDs in response. Unknown catalogue entry is PT404; known level with no receipts returns entries=[]. RPC returns one jsonb object.",
        "security": [
          {
            "ProjectKey": []
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/LeaderboardRequest"
              },
              "example": {
                "p_level_id": "L01",
                "p_level_version": 1
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "One best receipt per guest, at most 20 entries, stable ordering",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Leaderboard"
                },
                "example": {
                  "level_id": "L01",
                  "level_version": 1,
                  "generated_at": "2026-10-21T08:00:05Z",
                  "entries": [
                    {
                      "rank": 1,
                      "display_name": "Guest-7F2A90C1D4",
                      "steps": 2,
                      "elapsed_ms": 3200
                    }
                  ]
                }
              }
            }
          },
          "400": {
            "description": "INVALID_ARGUMENT / PT400",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "404": {
            "description": "LEVEL_NOT_FOUND / PT404",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "429": {
            "description": "Provider rate limit; inspect Retry-After",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          },
          "500": {
            "description": "Temporary server error; preserve local result",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RpcError"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "ProjectKey": {
        "type": "apiKey",
        "in": "header",
        "name": "apikey",
        "description": "Client publishable key, not a privileged service-role secret"
      },
      "GuestJWT": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      }
    },
    "schemas": {
      "ScoreRequest": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "p_submission_id": {
            "type": "string",
            "format": "uuid"
          },
          "p_level_id": {
            "type": "string",
            "enum": [
              "L01",
              "L02",
              "L03",
              "L04",
              "L05"
            ]
          },
          "p_level_version": {
            "type": "integer",
            "minimum": 1
          },
          "p_steps": {
            "type": "integer",
            "minimum": 1,
            "maximum": 100000
          },
          "p_elapsed_ms": {
            "type": "integer",
            "minimum": 0,
            "maximum": 86400000
          }
        },
        "required": [
          "p_submission_id",
          "p_level_id",
          "p_level_version",
          "p_steps",
          "p_elapsed_ms"
        ]
      },
      "ScoreReceipt": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "submission_id": {
            "type": "string",
            "format": "uuid"
          },
          "status": {
            "type": "string",
            "enum": [
              "accepted",
              "duplicate"
            ]
          },
          "is_personal_best": {
            "type": "boolean"
          },
          "received_at": {
            "type": "string",
            "format": "date-time"
          }
        },
        "required": [
          "submission_id",
          "status",
          "is_personal_best",
          "received_at"
        ]
      },
      "LeaderboardRequest": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "p_level_id": {
            "type": "string",
            "enum": [
              "L01",
              "L02",
              "L03",
              "L04",
              "L05"
            ]
          },
          "p_level_version": {
            "type": "integer",
            "minimum": 1
          }
        },
        "required": [
          "p_level_id",
          "p_level_version"
        ]
      },
      "LeaderboardEntry": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "rank": {
            "type": "integer",
            "minimum": 1,
            "maximum": 20
          },
          "display_name": {
            "type": "string",
            "pattern": "^Guest-[0-9A-F]{10}$"
          },
          "steps": {
            "type": "integer",
            "minimum": 1,
            "maximum": 100000
          },
          "elapsed_ms": {
            "type": "integer",
            "minimum": 0,
            "maximum": 86400000
          }
        },
        "required": [
          "rank",
          "display_name",
          "steps",
          "elapsed_ms"
        ]
      },
      "Leaderboard": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "level_id": {
            "type": "string",
            "enum": [
              "L01",
              "L02",
              "L03",
              "L04",
              "L05"
            ]
          },
          "level_version": {
            "type": "integer",
            "minimum": 1
          },
          "generated_at": {
            "type": "string",
            "format": "date-time"
          },
          "entries": {
            "type": "array",
            "maxItems": 20,
            "items": {
              "$ref": "#/components/schemas/LeaderboardEntry"
            }
          }
        },
        "required": [
          "level_id",
          "level_version",
          "generated_at",
          "entries"
        ]
      },
      "RpcError": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          },
          "details": {
            "type": "string",
            "nullable": true
          },
          "hint": {
            "type": "string",
            "nullable": true
          }
        },
        "required": [
          "code",
          "message",
          "details",
          "hint"
        ]
      },
      "AuthSession": {
        "type": "object",
        "properties": {
          "access_token": {
            "type": "string",
            "description": "Secret runtime token; never log or commit."
          },
          "refresh_token": {
            "type": "string"
          },
          "token_type": {
            "type": "string",
            "enum": [
              "bearer"
            ]
          },
          "expires_in": {
            "type": "integer"
          },
          "user": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string",
                "format": "uuid"
              },
              "is_anonymous": {
                "type": "boolean"
              }
            }
          }
        },
        "required": [
          "access_token",
          "refresh_token",
          "token_type",
          "expires_in",
          "user"
        ]
      }
    }
  }
}
```

## Appendix C — Verification report

# A01 design verification report

Run date: 21 October 2026 (Asia/Bangkok). These are source/design checks, not Flutter, Figma-runtime, participant, Supabase integration, or device-performance results.

## Level solution checks

| Level | Stored solution | Shortest valid moves | Search states | Result |
|---|---|---|---|---|
| L01/v1 | RR | 2 | 22 | PASS |
| L02/v1 | URDRUU | 6 | 148 | PASS |
| L03/v1 | LUUDDRRRUU | 10 | 1416 | PASS |
| L04/v1 | LLUUDDRRRRUU | 12 | 1797 | PASS |
| L05/v1 | LULUUDRRLDDRRUUUDRDRUULUL | 25 | 188499 | PASS |

## Static artifact checks

- PASS: 17 functional requirements, including 16 Must/Should requirements, have acceptance criteria, use-case/screen/component links, and generated manual test records.
- PASS: all 12 NFRs have use-case/screen/component links and planned verification records.
- PASS: 38 SVG screen/state frames and 9 vector diagrams parse as XML.
- PASS: 166 navigation hotspots reference valid frames and meet the 48 dp baseline minimum dimensions.
- PASS: Home reaches the main start/play/push/undo/pause/restart/completion/ranking/settings routes.
- INFO: fixture-only states selectable through the review menu: SCR-02c, SCR-05s, SCR-05x, SCR-06e, SCR-07e, SCR-07n, SCR-07o, SCR-07z.
- PASS: primary/secondary/error text token pairs meet 4.5:1 contrast on their intended surfaces.
- PASS: API request/response examples match the included schemas; score writes require a JWT and accept no caller-controlled owner.
- PASS: supplied source Markdown links resolve locally.
- INFO: supplementary PDF/SVG and mocked JavaScript review is documented in docs/review-notes.md; actual Figma/browser execution is still pending.
- PASS: PDF page tree, object offsets, stream lengths, and expected text validated (60 pages in the pre-report build).

## Checks still requiring real execution

- Figma importer execution, typography and reaction review, viewer-accessible prototype URL.
- 3–5 real interviews, evidence-based persona revision, and three participant usability sessions.
- Flutter unit/widget tests, TalkBack, physical-device layouts and timing measurements.
- Supabase deployment, RLS/authorization integration tests, real retries and network fault tests.
- Human visual PDF review and both team members' baseline approval.

Result: automated A01 design checks PASS. Final submission readiness remains PENDING.

