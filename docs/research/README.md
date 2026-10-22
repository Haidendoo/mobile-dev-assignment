# Research evidence register

## Honest current status

Desk research was performed using the primary sources cited in section 2 of the specification. No participant interviews or usability sessions have been conducted by the assistant. There are no real quotes, participant metrics, validated personas, or peer reviews in this package.

The two persona sketches in the specification are **proto-personas**. Replace or revise them after collecting evidence; do not submit them as interview-derived findings.

## Interviews: recruit 3–5 students

Use anonymous IDs P01–P05. Ask for consent to take notes; do not collect names, emails, student IDs, or unnecessary personal data. Participation must be voluntary. If audio is desired, obtain separate permission and retain recordings outside the public repo. Keep only anonymized notes in the submission.

Suggested 10–15 minute guide:

1. When did you last play a mobile puzzle game? Describe the situation.
2. How long do you normally have during a break?
3. What happens when a game loses its network connection?
4. How do you expect a box-pushing puzzle to behave? Can you explain pushing versus pulling?
5. What would you want after making a mistake or closing the app?
6. Which is more useful: personal bests, a leaderboard, both, or neither? Why?
7. What makes a mobile game difficult to read or control for you?
8. Show the design after the open questions. What is unclear? What would you remove?

Record responses in `interviews.csv`. The empty response cells are intentional. For every finding, preserve an anonymized observation, interpretation, affected requirement, and design decision in `findings.csv`. A suggested preference is not evidence of a universal need.

## Usability: three real sessions

Use U01–U03 and the same consent practice. Run the Figma prototype after importing and visually checking it. If using the local walkthrough instead, explicitly record that tool; do not call it a Figma session.

Tasks: start a level; explain crate/goal symbols; push the first crate; recover using undo; pause and resume; cancel a restart; find a completed level's leaderboard; recover from an offline score submission; find the sound setting.

Use neutral prompts and avoid teaching the task before an attempt. Record success, assistance, time, unexpected actions, issue severity, and participant comments. The walkthrough is scripted, so task time is not game completion time or app performance evidence. Store actual observations in `usability.csv` and design changes in the change log.

## Closing the evidence gap

- [ ] 3–5 interview rows with actual dates, consent, notes, and sources.
- [ ] Findings connected to FR/NFR IDs; conflicting feedback discussed.
- [ ] Both persona sketches revised using findings, with supporting participant IDs.
- [ ] Three usability records with task-level outcomes and issue descriptions.
- [ ] Changes applied and traced; unresolved issues explicitly accepted by the team.
- [ ] Consolidated PDF updated; no blank evidence represented as completed work.
