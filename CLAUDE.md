# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project: VILLE

**VILLE** is a minimal, local-only iOS app for reading Letterboxd reviews as full-screen **reels**. The user saves the Letterboxd usernames they want to read; VILLE pulls each member's public RSS feed and shows their written reviews one per page, swiped vertically.

It is the lighter stepping stone before the full social network (`../ville-du-cinema-mobile/`). Target: App Store before the end of 2026.

---

## Vision (keep in sync — update as the app evolves)

- **No accounts, no server, no social layer.** No likes, comments or reactions. Everything lives on the device.
- **Pure text.** Only written reviews. Lists and plain "watched" diary entries are never shown.
- **Reels feed.** Each launch is a new session: all saved reviews are shuffled, and none repeats until every one has been seen. Then a new shuffled round starts. No "running low" warnings.
- **Letterboxd-style review layout**: poster, title + year, "Review by", stars, like, rewatch, then the rich text (paragraphs, italics, bold, quotes, lists, links).
- **TMDB art**: poster and backdrop per film, each switchable off in Settings.
- **Share = link to the original review on Letterboxd**, never the review text or an image of it.
- **The library grows**: reviews stay saved after they drop out of the RSS window (RSS holds ~50 diary entries per member).

---

## Letterboxd ToS — hard rules

Checked 2026-10-21 against the "October 2026" Terms of Use.

- **RSS only.** Never fetch or parse Letterboxd HTML pages (clause 6.11 bans scraping). The RSS feed is the route Letterboxd offers on letterboxd.com/api-beta.
- **No exporting others' content** (6.8): sharing sends the Letterboxd URL only.
- **No index of a "significant portion"** (6.8): only reviews from members the user added, stored locally. No bundled or suggested member catalogs.
- **No competing business** (6.9): keep the app free, credit the author on every reel, and always link back to the original.
- **Logo** (19): only when linking to Letterboxd, only the official file from their Brand page, never implying a partnership. Never redraw it.
- Letterboxd has not answered our email (sent March 2026). Write again before release.

---

## Architecture

| Area | Choice |
|---|---|
| UI | SwiftUI only, iOS 26 (Liquid Glass) |
| State | `@Observable` view model, shared through `.environment` |
| Persistence | SwiftData, store name `VILLEReels` |
| Networking | `URLSession` + `XMLParser`, zero third-party deps |
| Concurrency | `async`/`await`; default actor isolation is `MainActor` |
| Images | `AsyncImage` + enlarged `URLCache.shared` |

**Data flow:** `RSSService` (Letterboxd RSS) → `FeedViewModel` upserts `Review`s into SwiftData → `FilmArtLoader` (via `TMDBService`) fills poster/backdrop paths → `ReelFeedView` reads reviews with `@Query` and orders them with `ReelQueue`.

**Secrets:** `VILLE/VILLE/Secrets.swift` holds the TMDB v3 key and is gitignored. Template: `Secrets.example.swift` at the repo root.

---

## Folder Structure

```
VILLE/VILLE/
├── VILLEApp.swift              # Entry point: SwiftData container, URLCache, view model
├── Secrets.swift               # (gitignored) TMDB key
├── Models/
│   ├── Review.swift            # One written review + display helpers
│   └── FollowedUser.swift      # A saved Letterboxd member
├── Services/
│   ├── RSSService.swift        # Fetch + parse RSS, keep reviews only
│   ├── ReviewHTML.swift        # Review HTML → paragraph/quote/list blocks
│   ├── TMDBService.swift       # Poster + backdrop by TMDB id
│   └── FilmArtLoader.swift     # Fills missing art, one TMDB request per film
├── ViewModels/
│   ├── FeedViewModel.swift     # Refresh, members, triggers art loading
│   └── ReelQueue.swift         # Session shuffle with no repeats per round
└── Views/
    ├── ReelFeedView.swift      # Vertical paging feed + top bar + empty states
    ├── ReelView.swift          # One reel + shared header, actions, backdrop
    ├── ReviewTextView.swift    # Draws ReviewHTML blocks
    ├── ReviewReaderView.swift  # Full text of a long review
    ├── MembersView.swift       # Add/remove members
    └── SettingsView.swift      # Poster/backdrop toggles + attributions
```

---

## Build

Open `VILLE/VILLE.xcodeproj` in Xcode 26+. The project uses synchronized folders, so new files inside `VILLE/VILLE/` are picked up automatically. Copy `Secrets.example.swift` to `VILLE/VILLE/Secrets.swift` first.

Build-check from the terminal (never boot the simulator — testing happens on a physical device):

```
xcodebuild -project VILLE/VILLE.xcodeproj -scheme VILLE -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

---

## Style Rules (follow in all new code)

- **Dark mode only.** Deep blacks, high contrast, cinematic.
- **Liquid Glass** for controls: `.buttonStyle(.glass)`, `.glassEffect()`, `GlassEffectContainer`.
- **Animations**: `.spring(response: 0.4, dampingFraction: 0.8)` as default.
- **Haptics** on meaningful interactions (`.sensoryFeedback`).
- **Typography**: system serif for review text and titles.
- **Reveal actions are one-way** (e.g. spoilers): no collapse toggle.
- **No UIKit** unless genuinely unavoidable. **No third-party deps** without explicit approval.
- **Never swallow errors** — log with `print` and context, or rethrow.
- **Never hand-draw logos** — use official asset files only.
