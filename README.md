# Forest Sokoban: The Lost Seeds

**Current work: A02 Android implementation has started.**

See the [latest development summary](docs/a02/development-summary.md) for completed changes, verification and remaining A02 work.

- [WSL + VS Code development](docs/a02/wsl-development.md)
- [Android application and alternative Windows setup](app/README.md)
- [Current progress and next tasks](project-step.md)
- [Current Figma UI and feature availability](docs/a02/figma-ui-migration.md)
- [Foundation verification and gameplay preview](docs/a02/verification.md)
- [Approved A02 implementation plan](docs/a02/implementation-plan.md)
- [Updated A02 API design contract](docs/a02/openapi.json)

The first implementation milestone provides a playable twelve-level offline
campaign foundation with MVVM, SQLite saves, and automated tests. Story/audio,
online rankings, email OTP and verified challenges are still pending. The updated
report in `rp/A1_Mobile_dev.zip` defines the A02 scope.

## Historical A01 package

The section below describes the original five-level A01 draft. Its generator and
artifacts remain available for reference; they do not describe the current A02
implementation status or the updated twelve-level scope.

An English specification and design package for a small Android box-pushing puzzle game by a two-person team. The mobile application is planned for A02.

Start with [project-step.md](project-step.md), then read the [consolidated specification](docs/A01-specification.md) or [PDF](deliverables/Forest-Sokoban-A01.pdf).

## Preview

Open `prototype/index.html` directly in a browser. This is a deterministic clickable frame walkthrough with sample data, not a functioning Flutter game or live leaderboard. No network, account, installation, or external assets are required.

For the Figma prototype, follow [prototype/figma/README.md](prototype/figma/README.md). The local import plugin creates editable layers and frame-to-frame interactions. Publishing a Figma URL requires running it in a Figma Design file and checking viewer access.

## Rebuild and validate

Requires Python 3.10+ only; no pip packages, credentials, or network needed.

```sh
python3 scripts/build.py
python3 scripts/validate.py
```

The build produces screen SVGs, diagram SVGs, the local walkthrough, the Figma plugin, CSV traceability/test tables, illustrated HTML, and a self-contained PDF with vector diagrams and mockups. Validation replays all five solutions, independently searches for shortest solutions, audits document cross-references, checks prototype reachability and hit targets, checks the API examples, and verifies PDF structure. It does not replace Figma-runtime, interview, usability, API integration, accessibility, or device-performance testing.

After adding the real Figma URL to `prototype/links.json`, run the build again to include it in the document. After collecting research, update the consolidated specification and evidence files, resolve any design changes, and regenerate the deliverables.

## Submission status

The current package is **v1.0-draft**, not a research-complete or team-approved submission. Interviews, evidence-backed personas, three usability sessions, member names, Figma-runtime verification, and the share URL remain pending. Detailed status and forms are in [docs/research/README.md](docs/research/README.md).

A portable [ZIP package](deliverables/Forest-Sokoban-A01-package.zip) includes the source, generated documents, screens, and importer. Supplementary artifact inspection is recorded in [docs/review-notes.md](docs/review-notes.md).

## Contents

- `docs/`: authoritative specification, API contract, evidence templates, and change log.
- `data/`: original level designs and reference solutions.
- `prototype/`: exported screens, local walkthrough, hotspot manifest, and Figma importer.
- `scripts/`: dependency-free document generation and design verification.
- `deliverables/`: generated PDF, HTML, and validation report.

All included vector artwork and layouts were authored for this package. No assets or maps from the reference screenshot/game were copied. See the specification for source attribution and AI-use disclosure.
