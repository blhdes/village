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
- **Reels feed with an end.** A session holds a set number of reviews (Settings → Session: 10/20/30/50, default 20), then the feed ends on a "Fin" card. "Keep reading" adds another session, but only on purpose. Coming back after 30+ minutes away starts a new session and refreshes the feeds. Pulling the first reel down refreshes them on demand; new reviews join upcoming reels, never the one on screen.
- **Picking a session** (`ReelSampler`): never-shown reviews first, newest first; then the ones shown longest ago (`Review.lastShownAt`), with a little chance. Members take turns, so one prolific member can't fill a session. The same member or film never appears twice in a row when avoidable. Reviews that arrive mid-session can take the place of upcoming reels, never the one on screen or the next.
- **Letterboxd-style review layout**: poster, "Review by", title + year, stars, like, rewatch (hideable: Settings → Stars and likes, on by default, to read the words before the verdict), the watched date, then the rich text (paragraphs, italics, bold, quotes, lists, links). Plain space separates header and text, no divider. Tapping the film title searches the web for it ("Title Year film" on Google, as the mobile app does), and links in the text open the same way: in Safari inside the app (`openURL(_:prefersInApp:)`, `OpenURLAction.inAppBrowser`), so reading continues after. "View on Letterboxd" keeps the system behavior (the Letterboxd app if installed).
- **TMDB art**: a different textless backdrop each time a film appears. Posters show the official one, or with Alternative posters on, a random one from TMDB's gallery (other countries' releases, textless art); tapping a poster flips to the next. Posters and backdrops are each switchable off in Settings.
- **Own identity, minimal**: VILLE must look clearly different from `../ville-du-cinema-mobile/` (also headed to the App Store), whose mark is a bold serif V with yellow, blue and red plates out of register. VILLE is the lighter synthesis, so its mark is plainer: a light serif italic in lowercase ending on a red full stop ("ville." in the app, "v." on the icon). The full stop says the feed has an end. No plates in the wordmark or icon.
- **Brand echo**: the Village plates (`OffsetPrint`) appear only on the Fin card, VILLE's one nod to its siblings. Brand colors otherwise live in the red dot and the star/like/rewatch trio.
- **Suggestions to start**: the People screen shows 5 random members from `SuggestedMember` (100 hand-picked critics, writers, filmmakers and creators who post written reviews often) until the user follows 10. Adding one swaps in someone new; shuffle shows others. English writers are suggested to everyone, others only to readers whose iPhone uses that language.
- **Share = link to the original review on Letterboxd**, never the review text or an image of it.
- **The library grows**: reviews stay saved after they drop out of the RSS window (RSS holds ~50 diary entries per member).

---

## Letterboxd ToS — hard rules

Checked 2026-10-21 against the "October 2026" Terms of Use.

- **RSS only.** Never fetch or parse Letterboxd HTML pages (clause 6.11 bans scraping). The RSS feed is the route Letterboxd offers on letterboxd.com/api-beta.
- **No exporting others' content** (6.8): sharing sends the Letterboxd URL only.
- **No index of a "significant portion"** (6.8 bans "creating… an index of any significant portion of the Service content"): only reviews from members the user added, stored locally. The one bundled list is `SuggestedMember`: about 100 hand-picked usernames and display names (out of 30M+ members), never reviews, and nothing is fetched until the user adds someone. Never scrape or import member lists, never pre-fetch suggested members' feeds, and don't grow it into a directory. Re-check the list against RSS before each release (2026-10-28 last).
- **No competing business** (6.9): keep the app free, credit the author on every reel, and always link back to the original.
- **Logo** (19): only when linking to Letterboxd, only the official file from their Brand page, never implying a partnership. Never redraw it.
- Letterboxd has not answered our email (sent March 2026). Write again before release.

---

## Architecture

| Area | Choice |
|---|---|
| UI | SwiftUI only, iOS 26 (Liquid Glass) |
| State | `@Observable` `FeedViewModel` (the library) and `ReelSession` (what's on screen), shared through `.environment` |
| Persistence | SwiftData, store name `VILLEReels` |
| Networking | `URLSession` + `XMLParser`, zero third-party deps |
| Concurrency | `async`/`await`; default actor isolation is `MainActor` |
| Images | Backdrops: `AsyncImage`. Posters: `PosterImageCache` (decoded in memory, the next tap's poster fetched ahead). Both over an enlarged `URLCache.shared` |

**Data flow:** `RSSService` (Letterboxd RSS) → `FeedViewModel` upserts `Review`s into SwiftData → `FilmArtLoader` (via `TMDBService`, one request per film with `append_to_response=images`) fills the poster and backdrop galleries → `ReelFeedView` reads reviews with `@Query` → `ReelSession` picks each session with `ReelSampler`, keeps it in a `ReelQueue`, and stamps `lastShownAt` on every review that appears.

**Secrets:** `VILLE/VILLE/Secrets.swift` holds the TMDB v3 key and is gitignored. Template: `Secrets.example.swift` at the repo root.

---

## Folder Structure

```
VILLE/VILLE/
├── VILLEApp.swift              # Entry point: SwiftData container, URLCache, view models
├── AppIcon.icon/               # Icon Composer app icon ("v." in Source Serif 4 Italic)
├── Secrets.swift               # (gitignored) TMDB key
├── Models/
│   ├── Review.swift            # One written review + display helpers
│   ├── FollowedUser.swift      # A saved Letterboxd member
│   └── SuggestedMember.swift   # Hand-picked members offered on the People screen
├── Services/
│   ├── RSSService.swift        # Fetch + parse RSS, keep reviews only
│   ├── ReviewHTML.swift        # Review HTML → paragraph/quote/list blocks
│   ├── TMDBService.swift       # Poster + backdrop galleries by TMDB id
│   ├── FilmArtLoader.swift     # Fills missing art, one TMDB request per film
│   └── PosterImageCache.swift  # Decoded posters in memory + prefetch
├── ViewModels/
│   ├── FeedViewModel.swift     # Library: refresh, members, triggers art loading
│   ├── ReelSession.swift       # On screen: current session, spoilers, breaks
│   ├── ReelQueue.swift         # The visit's reels: start, sync, keep reading
│   └── ReelSampler.swift       # Which reviews make a session, and their order
└── Views/
    ├── Brand/
    │   ├── Editorial.swift     # Headline with red dot, dateline, sheet title
    │   ├── OffsetPrint.swift   # Yellow/blue/red plates (Fin card only)
    │   └── VILLEWordmark.swift # The logo — change it here only
    ├── ReelFeedView.swift      # Vertical paging feed + end card + empty states
    ├── ReelTopBar.swift        # Wordmark, People/Settings buttons, pull-to-refresh dot, error banner
    ├── SessionEndView.swift    # "Fin" card at the end of a session
    ├── ReelView.swift          # One reel: header, text, spoiler gate, actions
    ├── ReelBackground.swift    # The reel's backdrop and its legibility fade
    ├── ReviewHeader.swift      # Poster, byline, title, rating, dateline (reel + reader)
    ├── PosterImage.swift       # Crossfading poster + LoadingSkeleton
    ├── ReviewActions.swift     # Share + View on Letterboxd (reel + reader)
    ├── ReviewTextView.swift    # Draws ReviewHTML blocks
    ├── ReviewReaderView.swift  # Full text of a long review
    ├── MembersView.swift       # Add/remove members
    ├── SuggestedMembersSection.swift # MembersView's "Suggested" section
    ├── SettingsView.swift      # Appearance, look toggles, session length + attributions
    └── Appearance.swift        # System / Light / Dark choice
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

- **Light, dark or system** (Settings → Appearance, default System). Reels sit on `Color.reelBackground` (pure black in dark, white in light). Never hardcode `.white`/`.black` for text or backgrounds — use `Color.primary` and `Color.reelBackground`. Masks may stay `.black` (only their opacity counts).
- **Brand colors**: `Color.brandYellow`, `Color.brandBlue`, `Color.brandRed` (asset catalog, light variants deepened to read on white). Sparingly and with meaning: the red full stop (wordmark and `EditorialHeadline`), plates (`OffsetPrint`, Fin card only), stars (`Color.starYellow`: brand yellow in dark mode, a deeper gold in light mode, because no bright yellow reaches 3:1 on white), like and errors (red), rewatch and links (blue). Everything else stays `Color.primary`. `AccentColor` is the brand red.
- **Legibility** (WCAG contrast, worst case = a white frame behind dark mode or a black one behind light mode): small text ≥ 4.5:1, large text and icons ≥ 3:1. No halos, glows or outlines around text: legibility comes from `ReelBackground`, whose image is sharp behind the top bar, then blurs and fades out across the header (measured in points from the header's top) so it's all but gone by the rating row. Re-check the numbers if you change the fade, the wash or the header layout; secondary text no lighter than `Color.primary.opacity(0.6)`. Controls must survive the largest non-accessibility text size (e.g. `ViewThatFits` in `ReviewActions`).
- **Logo**: the wordmark lives only in `VILLEWordmark`: "ville" in system serif italic, regular weight, plus a `Color.brandRed` full stop that breathes while refreshing (no image). The app icon is `AppIcon.icon` — edit it in Icon Composer. Its `v.svg` and `dot.svg` are the "v" and "." outlines of **Source Serif 4 Italic** (SIL OFL, wght 400, opsz 60), exported unchanged; never redraw them. Apple's New York can't be used in the icon (its license allows UI mock-ups only, not artwork), so Source Serif 4 stands in: its italic v is the closest open match.
- **Liquid Glass** for controls: `.buttonStyle(.glass)`, `.glassEffect()`, `GlassEffectContainer`.
- **Animations**: `.spring(response: 0.4, dampingFraction: 0.8)` as default.
- **Haptics** on meaningful interactions (`.sensoryFeedback`).
- **Typography — editorial, like the wordmark** (pieces in `Views/Brand/Editorial.swift`): system serif carries the voice (review text, titles, bylines, names, button labels inside the content); italic for secondary voice ("Review by", "Continue reading", "Keep reading", notes). Meta lines (dates, small notes) use `datelineStyle()`: spaced capitals. No dividers between a header and its text: space alone separates them. `EditorialHeadline` ends on the red full stop: big moments only (empty states), so the dot keeps its meaning. Sheet titles use `editorialTitle(_:)`. Prefer type and space over icons, lines and boxes.
- **Loading**: review text is always local; only art arrives later (TMDB lookups after a member is added, image downloads). Anything still on its way keeps its place with `LoadingSkeleton`, a quiet tile that breathes at the wordmark dot's pace: never an empty gap, a flat gray box or a layout jump. Show the skeleton only while something is really loading (`FeedViewModel.isLoadingArt`, a download in flight); a failed load gets a plain tile. Refreshing feeds never shows a spinner: the brand's red dot breathes instead (the wordmark's dot, or `RefreshDot` in the middle of the top bar during a pull-to-refresh, which `ReelFeedView` builds by hand with `onScrollGeometryChange` because `.refreshable`'s spinner can't be replaced).
- **Reveal actions are one-way** (e.g. spoilers): no collapse toggle.
- **No UIKit** unless genuinely unavoidable. **No third-party deps** without explicit approval.
- **Never swallow errors** — log with `print` and context, or rethrow.
- **Never hand-draw logos** — use official asset files only. In `Assets.xcassets` (downloaded 2026-10-21): `LetterboxdLogo` and `LetterboxdDots` (letterboxd.com/about/brand, light + dark variants), `TMDBLogo` (themoviedb.org/about/logos-attribution, "Alt short" SVG converted to PDF unchanged, because Xcode ignores the SVG's CSS styles).
