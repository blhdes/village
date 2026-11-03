# VILLE

A local-only iOS app for reading Letterboxd reviews as full-screen reels. No accounts, no server, no likes or comments. Just the writing.

## What it does

- Search for the Letterboxd members whose writing you like: type a username, or paste a profile link or a boxd.it short link. Read their reviews as reels before following them, or bookmark one without following. No login: VILLE reads their public RSS feeds.
- Not sure who to follow? Until you follow 10 people, the People screen suggests critics, writers, filmmakers and creators who post reviews often.
- Swipe through their written reviews one per screen. Each session has an end: 20 reviews by default, then a "Fin" card. Unread reviews come first, members take turns, and nothing repeats back to back.
- Each reel is set like a magazine page: poster, title, rating, then the full rich text. Reviews with spoilers stay covered until you tap, and stay uncovered after.
- Make the feed yours in Settings: how many reviews a session holds, showing each review only once, hiding very short reviews (one-liners under 10 words), hiding the stars and likes, posters (with alternative posters from TMDB) and backdrops (off by default), and light or dark appearance.
- Bookmark reviews to read again, or use Bookmarks as a watchlist: swipe one away once you've seen the film.
- One tap translates a review written in another language, right on the device. The app itself comes in eight languages.
- Tap "Review by …" to open the author's profile, report the review on Letterboxd, or unfollow.
- Share a review as a link to the original on Letterboxd.
- Everything is saved on the device. Reviews stay after they drop out of the RSS feed (up to each member's 100 newest), so your library grows over time.

Lists and "watched" entries without text are never shown.

## Why it exists

VILLE is the lighter sibling of [ville-du-cinema-mobile](https://github.com/blhdes/ville-du-cinema-mobile), a fuller social platform with accounts, comments and a Supabase backend. VILLE keeps only the part that made that app worth building: reading other people's film writing, presented beautifully.

## Letterboxd and TMDB

- Data comes only from Letterboxd's public RSS feeds, the route Letterboxd offers instead of its private API. VILLE never scrapes Letterboxd pages.
- Reviews belong to their authors. Every reel credits the author and links to the original.
- Suggestions are a short hand-picked list of usernames. Nothing is fetched from a suggested member until you open their reviews or follow them.
- Search fetches one member's feed, only when you ask. VILLE builds no index of members or reviews.
- VILLE is not affiliated with or endorsed by Letterboxd.
- This product uses the TMDB API but is not endorsed or certified by TMDB.

## Getting started

1. Open `VILLE/VILLE.xcodeproj` in Xcode 26+.
2. Copy `Secrets.example.swift` to `VILLE/VILLE/Secrets.swift` and add your TMDB v3 API key. The file is gitignored.
3. Build and run on an iPhone with iOS 26.2 or later.

## Architecture

SwiftUI + SwiftData + `@Observable`, `URLSession` + `XMLParser`, no third-party dependencies. See `CLAUDE.md` for the folder structure and the Letterboxd rules the code must follow.

## Status

Preparing 1.0 for the App Store (November 2026).

- [x] Members: follow and unfollow by username, profile link or boxd.it short link, saved on the device
- [x] Suggested members (100 hand-picked, checked for recent reviews) until you follow 10
- [x] Reviews-only RSS parsing with spoiler detection
- [x] Rich review text (paragraphs, italics, bold, quotes, lists, links), selectable
- [x] Sessions with an end ("Fin" card), unread-first sampling with members taking turns
- [x] Reading options: session length, each review only once, hide very short reviews
- [x] TMDB posters (with alternative posters) and backdrops, each switchable
- [x] Bookmarks, also as a watchlist
- [x] One-tap translation on the device, and the app in 8 languages
- [x] Byline menu: profile, report on Letterboxd, unfollow
- [x] Share as a link
- [x] Official Letterboxd and TMDB logos in Settings and "View on Letterboxd"
- [x] Appearance: System, Light or Dark
- [x] Brand: the "ville." wordmark and "v." icon in Source Serif 4 Italic
- [x] Email Letterboxd describing the app before release
- [x] Search: open any member's feed by username or link, then follow them or bookmark their reviews
- [ ] Demo mode, App Store screenshots and a first TestFlight build
- [ ] App Store submission
