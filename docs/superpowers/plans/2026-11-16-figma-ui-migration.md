# Figma UI Migration Implementation Plan

> **For agentic workers:** Execute inline with superpowers:executing-plans. Preserve existing user edits.

**Goal:** Replace every active foundation screen with the current Figma design.
**Architecture:** Keep CampaignViewModel, repositories and pure game rules. Bundle Figma layout definitions and SVG assets, rendered as native Flutter text, containers and interactive controls. Bind gameplay to real board state and swipe gestures.
**Tech Stack:** Flutter, Dart, flutter_svg, existing SQLite repository.
**Spec:** Figma EbPr2cisVRC7wgbkLjKSp9, S21+ and Trail/Campaign frames.

## Global Constraints
- English project content; landscape; Samsung Galaxy S21+ demo target.
- Preserve saved games and all 12 campaign maps.
- No archived frames, old ForestPanel, old backdrop or D-pad in active routes.
- Backend features remain explicitly unavailable until implemented; no sample results presented as real data.

## Review Focus
- Fresh install uses Play; existing save uses Continue.
- Paused and backgrounded game cannot accept swipes or accrue time.
- Locked chapters remain locked; unlocked chapter cards launch actual levels.
- Restart cancel preserves state; confirmation resets it.
- Layout remains usable on 640×360 and 960×432 with text scaling.

## Tasks
- [x] Add and observe failing navigation test: More is a full screen with Chapters and Profile; navigate to chapter and swipe a real level.
- [x] Bundle current Figma contexts/assets and native layout renderer; match menu, world map, chapter cards and guide.
- [x] Replace board skin, controls, pause/restart/clear views; retain keyboard support and real save behavior.
- [x] Wire new menu destinations to Figma screens with honest backend availability states.
- [x] Update behavioral tests, run full suite and analysis; build/install emulator APK and inspect screenshots.
- [x] Review changes and record migration scope and remaining backend work. Commit only when requested.
