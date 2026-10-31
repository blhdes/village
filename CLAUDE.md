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
- **Reels feed with an end.** A session holds a set number of reviews (Settings → Session: 10/20/30/50, default 20), then the feed ends on a "Fin" card. "Keep reading" adds another session, but only on purpose. Coming back after 30+ minutes away starts a new session and refreshes the feeds. Pulling the first reel down refreshes them on demand: the reel stays down below the top bar, leaving a strip where the red dot breathes, until the new reviews are in, then slides back up. New reviews join upcoming reels, never the one on screen.
- **Picking a session** (`ReelSampler`): never-shown reviews first, newest first; then the ones shown longest ago (`Review.lastShownAt`), with a little chance. Members take turns, so one prolific member can't fill a session. The same member or film never appears twice in a row when avoidable. Reviews that arrive mid-session can take the place of upcoming reels, never the one on screen or the next.
- **Letterboxd-style review layout**: poster, "Review by", title + year, stars, like, rewatch (set as monochrome type: "★★★½ · ♥ · ↻" in the text color, hideable: Settings → Stars and likes, on by default, to read the words before the verdict), the watched date, then the rich text (paragraphs, italics, bold, quotes, lists, links). Plain space separates header and text, no divider. Tapping the film title searches the web for it ("Title Year film" on Google, as the mobile app does), and links in the text open the same way: in Safari inside the app (`openURL(_:prefersInApp:)`, `OpenURLAction.inAppBrowser`), so reading continues after. "View on Letterboxd" keeps the system behavior (the Letterboxd app if installed).
- **TMDB art**: a different textless backdrop each time a film appears. Posters show the official one, or with Alternative posters on, a random one from TMDB's gallery (other countries' releases, textless art); tapping a poster flips to the next. Posters and backdrops are each switchable off in Settings.
- **Own identity, minimal**: VILLE must look clearly different from `../ville-du-cinema-mobile/` (also headed to the App Store), whose mark is a bold serif V with yellow, blue and red plates out of register. VILLE is the lighter synthesis, so its mark is plainer: a light serif italic in lowercase ending on a red full stop ("ville." in the app, "v." on the icon). The full stop says the feed has an end. No plates in the wordmark or icon.
- **Brand echo**: the Village plates (`OffsetPrint`) appear only on the Fin card, VILLE's one nod to its siblings. Brand colors otherwise live only in the red dot, links (blue) and errors (red).
- **Suggestions to start**: the People screen shows 5 random members from `SuggestedMember` (100 hand-picked critics, writers, filmmakers and creators who post written reviews often) until the user follows 10. Adding one swaps in someone new; shuffle shows others. English writers are suggested to everyone, others only to readers whose iPhone uses that language.
- **Share = link to the original review on Letterboxd**, never the review text or an image of it.
- **Bookmarks**: the bookmark under a review (next to Share) keeps it on the device (`Review.bookmarkedAt`), with no account or sync. They open from one quiet row in People (`BookmarksView`), newest bookmark first. Tapping one opens all of them in full on one page that scrolls from review to review (`BookmarksReader`), starting at the one tapped. The bookmark button is the only way to take one off (no swipe in the list): on that page the review stays put with an empty bookmark, so a second tap puts it back, and only the list drops it. With posters on, a bookmark keeps the poster that was on screen (`Review.bookmarkPosterIndex`); tapping it on that page flips to the next and keeps that one. A bookmark is never trimmed and stays after its member is removed: it leaves the feed (which only shows followed members) but stays in Bookmarks. A spoiler review bookmarked unrevealed stays covered in the reader (`SpoilerGate`), so it can wait until after the film.
- **Selectable text**: the review text can be long-pressed and copied, on the reel and in the reader (iOS 27: any stretch of a paragraph; iOS 26: the whole paragraph). Selection stays inside one paragraph, because each block is its own `Text`.
- **One-tap translation** (like X's translate button): when a review isn't in the reader's language, a note under its dateline offers "Translate from English". The reader's language is the first of `Locale.preferredLanguages` that Translation supports (not `Locale.current`, which only knows VILLE's interface languages): VILLE's own language when one is picked for it in iOS Settings, else the iPhone's, so a Catalan iPhone with Spanish second reads in Spanish. The note and the credit are written out per source language (`ReviewTranslation.offer`/`credit`), never a "from %@" template, because French says "de l'anglais" but "du japonais", German "aus dem Englischen", Italian "dallo spagnolo". One tap swaps the text in place; the note then reads "Translated from English · Show original", a translator's credit as a book prints it. Everything runs on the device: `NaturalLanguage` detects the language, Apple's Translation framework translates (Apple Intelligence's models when available, else the downloadable Translate languages, which the system offers to download on first use). Each block is translated on its own, so quotes and lists keep their shape; from iOS 26.4 italics, bold and links survive too. Translations live in memory until the app quits, shared by the reel and the reader, and are never saved or shared. "Show original" is a view switch, not a reveal, so it doesn't break the one-way reveal rule.
- **Eight languages**: English (source), Spanish, German, French, Italian, Japanese, Portuguese (Brazil), Simplified Chinese, all in `Localizable.xcstrings`. Settings → Language shows the current one and opens VILLE's page in iOS Settings to pick another (Apple's per-app language). No in-app picker: it could only apply after a manual restart, and system sheets wouldn't follow it. Reviews always stay as written unless translated.
- **The library grows, up to a limit**: reviews stay saved after they drop out of the RSS window (RSS holds ~50 diary entries per member), but each member keeps only their newest 100 (`LibraryTrimmer`, run once per launch before the first session, so no reel on screen disappears), plus bookmarks. Downloads (posters, backdrops, TMDB and RSS answers) share one `URLCache` capped at 150 MB in Caches, which iOS can also clear. Settings → Storage shows both sizes and can clear the images.

---

## Letterboxd ToS — hard rules

Checked 2026-10-21 against the "October 2026" Terms of Use.

- **RSS only.** Never fetch or parse Letterboxd HTML pages (clause 6.11 bans scraping). The RSS feed is the route Letterboxd offers on letterboxd.com/api-beta.
- **No exporting others' content** (6.8): sharing sends the Letterboxd URL only. Copying and translating are the reader's own, on the device, like selecting text or "Translate" in Safari on letterboxd.com: translations are never stored, synced or sent anywhere, and Share never carries them.
- **No index of a "significant portion"** (6.8 bans "creating… an index of any significant portion of the Service content"): only reviews from members the user added, stored locally. The one bundled list is `SuggestedMember`: about 100 hand-picked usernames and display names (out of 30M+ members), never reviews, and nothing is fetched until the user adds someone. Never scrape or import member lists, never pre-fetch suggested members' feeds, and don't grow it into a directory. Re-check the list against RSS before each release (2026-10-28 last).
- **No competing business** (6.9): keep the app free, credit the author on every reel, and always link back to the original.
- **Logo** (19): only when linking to Letterboxd, only the official file from their Brand page, never implying a partnership. Never redraw it.
- Letterboxd emails, both to api@letterboxd.com in one thread: 2026-01-09 (API access for a web app, unanswered) and 2026-10-31 (follow-up about VILLE using RSS, asking for a written OK). Record their answer in `store/RELEASE.md`.

---

## Architecture

| Area | Choice |
|---|---|
| UI | SwiftUI only, iOS 26 (Liquid Glass) |
| State | `@Observable` `FeedViewModel` (the library), `ReelSession` (what's on screen) and `ReviewTranslator` (reviews shown translated), shared through `.environment` |
| Persistence | SwiftData, store name `VILLEReels` |
| Networking | `URLSession` + `XMLParser`, zero third-party deps |
| Concurrency | `async`/`await`; default actor isolation is `MainActor` |
| Images | Backdrops: `AsyncImage`. Posters: `PosterImageCache` (decoded in memory, the next tap's poster fetched ahead). Both over `URLCache.shared`, set up and capped by `LocalStorage` |

**Data flow:** `RSSService` (Letterboxd RSS) → `FeedViewModel` upserts `Review`s into SwiftData → `FilmArtLoader` (via `TMDBService`, one request per film with `append_to_response=images`) fills the poster and backdrop galleries → `ReelFeedView` reads reviews with `@Query` → `ReelSession` picks each session with `ReelSampler`, keeps it in a `ReelQueue`, and stamps `lastShownAt` on every review that appears. Translation: `TranslationNote` (in `ReviewHeader`) gets a session from `.translationTask` → `ReviewTranslator` → `ReviewTranslation` → the reel and reader draw `translator.blocks(for:)`.

**Secrets:** `VILLE/VILLE/Secrets.swift` holds the TMDB v3 key and is gitignored. Template: `Secrets.example.swift` at the repo root.

---

## Folder Structure

```
VILLE/VILLE/
├── VILLEApp.swift              # Entry point: SwiftData container, URLCache, view models
├── AppIcon.icon/               # Icon Composer app icon ("v." in Source Serif 4 Italic)
├── Secrets.swift               # (gitignored) TMDB key
├── PrivacyInfo.xcprivacy       # Privacy manifest: UserDefaults (CA92.1), file sizes (C617.1), no tracking, nothing collected
├── Localizable.xcstrings       # Every interface string in the 8 languages
├── InfoPlist.xcstrings         # Bundle name (not translated)
├── Models/
│   ├── Review.swift            # One written review + display helpers
│   ├── FollowedUser.swift      # A saved Letterboxd member
│   └── SuggestedMember.swift   # Hand-picked members offered on the People screen
├── Services/
│   ├── RSSService.swift        # Fetch + parse RSS, keep reviews only
│   ├── ReviewHTML.swift        # Review HTML → paragraph/quote/list blocks
│   ├── TMDBService.swift       # Poster + backdrop galleries by TMDB id
│   ├── FilmArtLoader.swift     # Fills missing art, one TMDB request per film
│   ├── LibraryTrimmer.swift    # Keeps each member's newest 100 reviews + bookmarks
│   ├── LocalStorage.swift      # Download cache limit, sizes on disk, clear images
│   ├── ReviewTranslation.swift # Detects a review's language, translates its blocks (on device), "Translate from…" sentences
│   └── PosterImageCache.swift  # Decoded posters in memory + prefetch
├── ViewModels/
│   ├── FeedViewModel.swift     # Library: refresh, members, triggers art loading
│   ├── ReelSession.swift       # On screen: current session, spoilers, breaks
│   ├── ReelQueue.swift         # The visit's reels: start, sync, keep reading
│   ├── ReelSampler.swift       # Which reviews make a session, and their order
│   └── ReviewTranslator.swift  # Which reviews show translated (memory only), into which language
└── Views/
    ├── Brand/
    │   ├── Editorial.swift     # Headline with red dot, dateline, sheet title
    │   ├── OffsetPrint.swift   # Yellow/blue/red plates (Fin card only)
    │   └── VILLEWordmark.swift # The logo — change it here only
    ├── ReelFeedView.swift      # Vertical paging feed + end card + empty states
    ├── PullToRefresh.swift     # The pull, the strip held open while refreshing, the red dot
    ├── ReelTopBar.swift        # Wordmark, People/Settings buttons, pull-to-refresh dot, error banner
    ├── SessionEndView.swift    # "Fin" card at the end of a session
    ├── ReelView.swift          # One reel: header, text, spoiler gate, actions
    ├── SpoilerGate.swift       # Glass shield over spoilers, tap to reveal (reel + reader)
    ├── ReelTextBox.swift       # A reel's text: fade + "Continue reading" when cut off
    ├── ReelBackground.swift    # The reel's backdrop and its legibility fade
    ├── ReviewHeader.swift      # Poster, byline, title, rating, dateline (reel + reader)
    ├── PosterImage.swift       # Crossfading poster + LoadingSkeleton
    ├── TranslationNote.swift   # "Translate from English" under the dateline
    ├── ReviewActions.swift     # Share + View on Letterboxd + bookmark (reel + reader)
    ├── ReviewTextView.swift    # Draws ReviewHTML blocks
    ├── ReviewReaderView.swift  # Full text of a review: sheet from a reel, and each review on the Bookmarks page
    ├── MembersView.swift       # Add/remove members, Bookmarks row
    ├── BookmarksView.swift     # Bookmarked reviews from People, and the page that scrolls through them
    ├── SuggestedMembersSection.swift # MembersView's "Suggested" section
    ├── SettingsView.swift      # Appearance, language, look toggles, session length, storage + attributions
    ├── StorageSection.swift    # Settings → Storage: sizes, limits, clear images
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

## Release

Publishing follows the global `app-store-release` skill. Its state for VILLE lives in `store/RELEASE.md` (IDs, decisions, phase checklists, risks): read it first. App Store Connect record: `ville.` (Apple ID 6829207754), bundle `agu.VILLE`, iPhone only, portrait. Never put "Letterboxd" in the store name, subtitle or keywords.

---

## Style Rules (follow in all new code)

- **Light, dark or system** (Settings → Appearance, default System). Reels sit on `Color.reelBackground` (pure black in dark, white in light). Never hardcode `.white`/`.black` for text or backgrounds — use `Color.primary` and `Color.reelBackground`. Masks may stay `.black` (only their opacity counts).
- **Brand colors**: `Color.brandYellow`, `Color.brandBlue`, `Color.brandRed` (asset catalog, light variants deepened to read on white). Sparingly and with meaning: the red full stop (wordmark and `EditorialHeadline`), plates (`OffsetPrint`, Fin card only), errors (red), links (blue). Everything else stays `Color.primary`, including the stars, like and rewatch marks, which read as type: SF Symbols at small scale on the serif baseline, New York's own "½", middle dots between. `AccentColor` is the brand red.
- **Legibility** (WCAG contrast, worst case = a white frame behind dark mode or a black one behind light mode): small text ≥ 4.5:1, large text and icons ≥ 3:1. No halos, glows or outlines around text: legibility comes from `ReelBackground`: the whole 16:9 frame, sharp behind the top bar, melts into a blurred copy across the header and fades out through the first lines of the review (measured in points from the header's top). Under the 0.45 wash the image never shows above 68% where the header text starts, which is what keeps "Review by" (0.8 opacity) at 4.5:1 on a white frame. Re-check the numbers if you change the fade, the wash, the header's text opacities or its layout; secondary text no lighter than `Color.primary.opacity(0.6)`. Controls must survive the largest non-accessibility text size (e.g. `ViewThatFits` in `ReviewActions`).
- **Logo**: the wordmark lives only in `VILLEWordmark`: "ville" in system serif italic, regular weight, plus a `Color.brandRed` full stop that breathes while refreshing (no image). The app icon is `AppIcon.icon` — edit it in Icon Composer. Its `v.svg` and `dot.svg` are the "v" and "." outlines of **Source Serif 4 Italic** (SIL OFL, wght 400, opsz 60), exported unchanged; never redraw them. Apple's New York can't be used in the icon (its license allows UI mock-ups only, not artwork), so Source Serif 4 stands in: its italic v is the closest open match.
- **Liquid Glass** for controls: `.buttonStyle(.glass)`, `.glassEffect()`, `GlassEffectContainer`.
- **Animations**: `.spring(response: 0.4, dampingFraction: 0.8)` as default.
- **Haptics** on meaningful interactions (`.sensoryFeedback`).
- **Typography — editorial, like the wordmark** (pieces in `Views/Brand/Editorial.swift`): system serif carries the voice (review text, titles, bylines, names, button labels inside the content); italic for secondary voice ("Review by", "Continue reading", "Keep reading", notes). Meta lines (dates, small notes) use `datelineStyle()`: spaced capitals. No dividers between a header and its text: space alone separates them. `EditorialHeadline` ends on the red full stop: big moments only (empty states), so the dot keeps its meaning. Sheet titles use `editorialTitle(_:)`. Prefer type and space over icons, lines and boxes.
- **Loading**: review text is always local; only art arrives later (TMDB lookups after a member is added, image downloads). Anything still on its way keeps its place with `LoadingSkeleton`, a quiet tile that breathes at the wordmark dot's pace: never an empty gap, a flat gray box or a layout jump. Show the skeleton only while something is really loading (`FeedViewModel.isLoadingArt`, a download in flight); a failed load gets a plain tile. Refreshing feeds never shows a spinner: the brand's red dot breathes instead (the wordmark's dot, or `RefreshDot` in the middle of the top bar during a pull-to-refresh). The pull-to-refresh is built by hand in `PullToRefresh.swift` (`onScrollGeometryChange` + `onScrollPhaseChange`), because `.refreshable`'s spinner can't be replaced. While it runs, `pullToRefreshHold` keeps the reels drawn lower (a `visualEffect` offset, so paging and the bounce stay native) and `FeedViewModel.refreshAll()` joins a refresh already running, so the strip closes exactly when the reviews are in.
- **Localization**: every visible or spoken string goes through `Text("…")`/`LocalizedStringKey` or `String(localized:)` (a plain `String` parameter or computed property is invisible to the catalog), and ships translated into all 7 languages in `Localizable.xcstrings`. After adding strings, sync the catalog with `xcodebuild -exportLocalizations -project VILLE/VILLE.xcodeproj -localizationPath /tmp/loc -scheme VILLE` (a plain build doesn't). Counts use plural variations, two-argument keys positional specifiers (`%1$@`, `%2$@`). A sentence around a language name is written out per language. Tone: es *tú* (Spain), de *du*, fr *vous*; "review" is reseña · Kritik · critique · recensione · レビュー · resenha · 影评. Brand names stay as they are.
- **Reveal actions are one-way** (e.g. spoilers): no collapse toggle.
- **No UIKit** unless genuinely unavoidable. **No third-party deps** without explicit approval.
- **Never swallow errors** — log with `print` and context, or rethrow.
- **Never hand-draw logos** — use official asset files only. In `Assets.xcassets` (downloaded 2026-10-21): `LetterboxdLogo` and `LetterboxdDots` (letterboxd.com/about/brand, light + dark variants), `TMDBLogo` (themoviedb.org/about/logos-attribution, "Alt short" SVG converted to PDF unchanged, because Xcode ignores the SVG's CSS styles).
