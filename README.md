# VILLE

A minimal, 100% offline-first iOS app for discovering cinema through Letterboxd reviews — no accounts, no social feed, no server. Just a calm, cinematic reading experience built on Letterboxd's public RSS feeds.

> **Status: paused at scaffold stage.** The app skeleton compiles and runs — entry point, data model, RSS service, view model, and three views are all in place — but it hasn't been iterated on since the initial commit. See [Status](#status) below.

## What it does

- Add the Letterboxd usernames of people you follow (no login required — public RSS only).
- See a single, merged, reverse-chronological feed of their reviews as large cinematic cards.
- Tap a card to open an immersive, full-screen reader.
- Everything is cached locally via SwiftData, so the feed works offline after the first fetch.

## Why it exists

VILLE is a from-scratch, native rewrite of one part of [village-du-cinema](https://github.com/blhdes/ville-du-cinema-mobile) — an existing Expo/React Native app that had grown into a fuller social platform (accounts, comments, likes, a Supabase backend). VILLE strips all of that away and keeps only the thing that made it worth building in the first place: reading other people's film writing, presented beautifully.

It shares no code, language, or dependency graph with the Expo app or its web counterpart — it references them only as porting material when logic (RSS parsing, HTML sanitization, rating extraction) needs to be carried over.

## Architecture

| Area | Choice | Why |
|---|---|---|
| UI | SwiftUI only (iOS 18+) | Latest design system (Liquid Glass), no UIKit bridges |
| State | `@Observable` (Observation framework) | Modern, value-type friendly, replaces `ObservableObject` |
| Persistence | SwiftData, single source of truth | First-class SwiftUI integration, offline-first by design |
| Networking | `URLSession` + `XMLParser` (Foundation) | Zero third-party dependencies |
| Concurrency | `async`/`await` throughout | No Combine, no callbacks |
| Visual design | Liquid Glass, dark mode only | Cinematic, premium feel |
| Target | iOS 18+, iPhone 13 and newer | Full use of Liquid Glass + Observation |

**Data flow:** `RSSService` fetches and parses a user's Letterboxd RSS feed → `FeedViewModel` upserts the results into SwiftData → `FeedView` reads from SwiftData via `@Query`. The UI never talks to `RSSService` directly, so it looks and behaves identically online and offline.

## Project structure

```
VILLE/
├── VILLEApp.swift              # @main entry point, ModelContainer, dark-mode enforcement
├── Models/
│   └── Review.swift            # SwiftData @Model for a single review
├── Services/
│   └── RSSService.swift        # Async Letterboxd RSS fetch + XML parsing
├── ViewModels/
│   └── FeedViewModel.swift     # @Observable, orchestrates refresh + cache
└── Views/
    ├── FeedView.swift          # Main screen
    ├── ReviewCard.swift        # Liquid Glass review card
    └── ReviewDetailView.swift  # Immersive full-screen reader
```

## Getting started

1. Clone the repo and open `VILLE/VILLE.xcodeproj` in Xcode 16+.
2. Build & run (⌘R) on an iOS 18+ simulator or device.
3. No API keys, accounts, or third-party dependencies to configure — the app talks directly to Letterboxd's public RSS endpoints.

## Style rules

- Dark mode only — deep blacks, high contrast, cinematic.
- Liquid Glass throughout (`.glassBackgroundEffect`, `.glassEffect()`) in place of flat fills.
- Large, near-full-width cards; spring animations (`response: 0.4, dampingFraction: 0.8`) as the default motion.
- Haptic feedback on every meaningful interaction.
- No UIKit unless unavoidable; no third-party dependencies without explicit sign-off.

## Status

Paused at scaffold stage. The Xcode project and all five source files exist and build, but there's no iteration history yet beyond the initial commit. Rough next steps, not yet ordered or committed to:

- [ ] Followed-users management UI (add/remove Letterboxd usernames)
- [ ] Rich-text rendering in the reader (blockquotes, images, bold) in place of the current basic HTML renderer
- [ ] Word-level text selection in the reader
- [ ] Persist followed usernames in SwiftData (currently hard-coded seed values)
- [ ] Custom typography
- [ ] Multi-tab layout (Feed / Saved / Profile)
- [ ] Widget / Live Activities
