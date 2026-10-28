# VILLE

A local-only iOS app for reading Letterboxd reviews as full-screen reels. No accounts, no server, no likes or comments. Just the writing.

## What it does

- Save the Letterboxd usernames of people whose writing you like. No login: VILLE reads their public RSS feeds.
- Not sure who to follow? Until you follow 10 people, the People screen suggests critics, writers, filmmakers and creators who post reviews often.
- Swipe through their written reviews one per screen. Each session has an end: 20 reviews by default, then a "Fin" card. Unread reviews come first, members take turns, and nothing repeats back to back.
- Each reel shows the review the way Letterboxd lays it out: poster, title, rating, and the full rich text. A TMDB backdrop sits behind it, a different one each time the film comes round.
- See alternative posters from TMDB (other countries' releases, textless art): tap a poster to flip through them.
- Turn posters or backdrops off for text only.
- Share a review as a link to the original on Letterboxd.
- Everything is saved on the device. Reviews stay after they drop out of the RSS feed, so your library grows over time.

Lists and "watched" entries without text are never shown.

## Why it exists

VILLE is the lighter sibling of [ville-du-cinema-mobile](https://github.com/blhdes/ville-du-cinema-mobile), a fuller social platform with accounts, comments and a Supabase backend. VILLE keeps only the part that made that app worth building: reading other people's film writing, presented beautifully.

## Letterboxd and TMDB

- Data comes only from Letterboxd's public RSS feeds, the route Letterboxd offers instead of its private API. VILLE never scrapes Letterboxd pages.
- Reviews belong to their authors. Every reel credits the author and links to the original.
- Suggestions are a short hand-picked list of usernames. Nothing is fetched from a suggested member until you add them.
- VILLE is not affiliated with or endorsed by Letterboxd.
- This product uses the TMDB API but is not endorsed or certified by TMDB.

## Getting started

1. Open `VILLE/VILLE.xcodeproj` in Xcode 26+.
2. Copy `Secrets.example.swift` to `VILLE/VILLE/Secrets.swift` and add your TMDB v3 API key. The file is gitignored.
3. Build and run on an iOS 26 device.

## Architecture

SwiftUI + SwiftData + `@Observable`, `URLSession` + `XMLParser`, no third-party dependencies. See `CLAUDE.md` for the folder structure and the Letterboxd rules the code must follow.

## Status

Reels rebuild in progress (October 2026).

- [x] Members: add/remove, saved on device
- [x] Suggested members (100 hand-picked, checked for recent reviews) until you follow 10
- [x] Reviews-only RSS parsing with spoiler detection
- [x] Rich review text (paragraphs, italics, bold, quotes, lists, links)
- [x] Sessions with an end ("Fin" card), unread-first sampling with members taking turns
- [x] TMDB poster and backdrop, each toggleable; rotating backdrops and alternative posters
- [x] Share as a link
- [x] Official Letterboxd and TMDB logos in Settings / "View on Letterboxd"
- [x] Appearance: System / Light / Dark
- [x] Brand: VILLE wordmark and app icon from the Village du Cinéma offset V
- [ ] Email Letterboxd describing the app before release
- [ ] App Store submission
