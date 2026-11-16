# Push motion polish

The board now slides the player, shadow and movable pieces between cells over 170 ms with ease-out timing. Stable crate identities keep a pushed crate moving instead of removing/recreating its sprite. Undo uses the same slide. A forward push adds a subtle 280 ms settling motion and fading dust; arriving on an altar adds a gold ring and a delayed completion badge. All three chapter sprite families use the effect; the Figma SVG files are unchanged.

The winning board remains visible for 300 ms so the last push can finish before Level clear appears. Score persistence, victory detection and timer freeze still happen immediately in the ViewModel; the short delay is presentation only. Further movement remains rejected after winning.

Restart creates a fresh board animation state. Pause stops movement effects. The system's reduced-motion preference uses immediate positioning and skips the victory presentation delay. No audio, vibration, new dependency or game rule is added.

Verification: **53 host tests passed**, including mid-transition positions for a push and Undo, immediate reduced-motion placement, and the final push remaining on screen before the result. Analysis is clean. A read-only code review found no important regression. Rendered midpoint/altar frames are under `push-previews/`; physical Samsung S21+ motion/performance acceptance remains pending.

AI assistance: Codex implemented and reviewed the Flutter animation changes and produced the automated verification. Team visual approval and individual understanding remain the team's responsibility.
