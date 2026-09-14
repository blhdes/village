# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project: VILLE

**VILLE** is a brand-new, minimal, 100% offline-first iOS app — a beautiful Letterboxd RSS client focused exclusively on **discovering cinema through reviews**.

It is a radical simplification / refactor of the existing React Native + Expo app `ville-du-cinema-mobile`. VILLE strips out:
- Authentication (no Supabase, no accounts)
- Social features (no takes, comments, follows-via-Supabase)
- The web layer
- React Native / Expo / JS entirely

…and focuses on **one thing**: reading Letterboxd reviews from followed users, beautifully, fully offline-first.

---

## Vision (keep in sync — update as the app evolves)

- A phone-first, calm, cinematic reading app.
- User adds Letterboxd usernames (no login — Letterboxd public RSS only).
- Feed = merged, reverse-chronological list of review cards from all followed users.
- Tap a card → immersive reader.
- Everything is cached via SwiftData → works offline after first fetch.
- No social layer, no auth, no server. Pure client.

Future (not this step):
- Multi-tab layout (Feed / Saved / Profile) — TabView is already scaffolded.
- Followed-users management UI.
- Clippings / highlights (like the reference project's `ReviewReaderScreen`).
- Custom fonts + refined typography.
- Widget / Live Activities.

---

## Architecture Decisions

| Area | Choice | Reason |
|---|---|---|
| UI | **SwiftUI only** (iOS 18+) | Latest design system (Liquid Glass), no UIKit bridges |
| State | **`@Observable`** (Observation framework) | Modern, value-type friendly, replaces ObservableObject |
| Persistence | **SwiftData** as single source of truth | First-class SwiftUI integration, offline-first by design |
| Networking | `URLSession` + `XMLParser` (Foundation) | Zero third-party deps |
| Concurrency | `async/await` everywhere | No Combine, no callbacks |
| Design | **Liquid Glass** (`.glassEffect`, `.glassBackgroundEffect`), dark-only | Cinematic, premium feel |
| Target | iOS 18+, iPhone 13 and newer | Allows full use of Liquid Glass + Observation |
| Deps | **None** (outside Apple SDKs) | Keep it minimal, future-proof |

**Data flow**: `RSSService` → `FeedViewModel` → SwiftData `Review` objects → `@Query` in `FeedView`. Pull-to-refresh re-fetches RSS, upserts into SwiftData by `id`. The view always reads from SwiftData (never directly from RSSService), so the UI is identical online and offline.

---

## Folder Structure

```
VILLE/
├── VILLEApp.swift              # @main App entry, ModelContainer, dark-mode enforcement
├── Models/
│   └── Review.swift            # SwiftData @Model — mirrors Review type from RN project
├── Services/
│   └── RSSService.swift        # Async Letterboxd RSS fetch + XML parsing
├── ViewModels/
│   └── FeedViewModel.swift     # @Observable, orchestrates refresh + cache
└── Views/
    ├── FeedView.swift          # Main screen, TabView-ready
    ├── ReviewCard.swift        # Liquid Glass cinematic card
    └── ReviewDetailView.swift  # Immersive full-screen reader
```

---

## Reference Project

Full React Native codebase being distilled from (already cloned locally):

- **Path**: `../ville-du-cinema-mobile/`
- **Branch to use**: `feature/tos-compliant-rebuild`
- **GitHub**: https://github.com/blhdes/ville-du-cinema-mobile/tree/feature/tos-compliant-rebuild

Key files to cross-reference when extending VILLE:

| Concern | Reference file |
|---|---|
| RSS fetching + pagination | `services/feed.ts` → `fetchFeed()`, `fetchUserFeed()`, `_fetchUserFeed()` |
| `Review` TypeScript type | `types/database.ts` → `interface Review` (line ~461) |
| HTML sanitation | `utils/html.ts` + `cleanDescription()` in `services/feed.ts` |
| Card rendering + truncation | `components/ReviewCard.tsx` |
| Immersive reader + word selection | `screens/ReviewReaderScreen.tsx` |
| Feed screen composition | `screens/FeedScreen.tsx` |

When porting logic, **preserve behavior** (e.g. rating extraction regex, list-skipping, poster-image stripping) — it's already ToS-compliant and battle-tested.

---

## Build / Run

This repo ships Swift source files + a CLAUDE.md but **does not yet ship an Xcode project file** (`.xcodeproj`). Create one once:

1. Open Xcode → **File ▸ New ▸ Project…** → iOS ▸ App.
2. Settings:
   - Product Name: **VILLE**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - Minimum Deployment: **iOS 18.0**
3. Save inside this directory (`village/`) so Xcode creates `village/VILLE.xcodeproj`.
4. In Xcode's Project Navigator, delete the template-generated `ContentView.swift` and `VILLEApp.swift`.
5. Right-click the `VILLE` group → **Add Files to "VILLE"…** → select the `Models`, `Services`, `ViewModels`, `Views` folders *and* the root `VILLEApp.swift`. Choose **"Create groups"**.
6. In target settings, enable **User Interface Style = Dark** (Info.plist key `UIUserInterfaceStyle`).
7. Build & run (⌘R).

From then on: standard `⌘B` build, `⌘R` run, `⌘U` tests.

---

## Style Rules (follow in all new code)

- **Dark mode only.** Deep blacks, high contrast, cinematic.
- **Liquid Glass everywhere**: prefer `.glassBackgroundEffect(.regular)`, `.glassEffect()`, vibrancy materials over flat fills.
- **Large cinematic cards** (~full-width on iPhone).
- **Animations**: `.spring(response: 0.4, dampingFraction: 0.8)` as default.
- **Haptics** on every meaningful interaction (`UIImpactFeedbackGenerator`, `.sensoryFeedback` modifier).
- **Typography**: system fonts for now (`.largeTitle`, `.title`, `.body` with `.serif` / `.rounded` designs). Custom fonts later.
- **No UIKit** unless genuinely unavoidable (haptics are fine).
- **No third-party deps** without explicit approval.
- **Never use `try/catch` that swallows errors silently** — always log via `print` or rethrow with context.
- **`any` is banned** (Swift equivalent: avoid `Any`, prefer precise types).

---

## Original Prompt (for context persistence)

> We are building a brand-new minimal iOS app called **VILLE**. VILLE is a lightweight, 100% offline-first Letterboxd RSS client focused exclusively on discovering cinema through beautiful reviews. It is a radical simplification / refactor of the existing "Village du Cinema" / "Ville du Cinema Mobile" app (`../ville-du-cinema-mobile/`, branch `feature/tos-compliant-rebuild`).
>
> Target iOS 18+, SwiftUI only, Liquid Glass, dark cinematic aesthetic, SwiftData single source of truth, `@Observable` view models, no UIKit, no third-party dependencies. First step: project skeleton + Feed screen + ReviewCards + basic immersive reader.
