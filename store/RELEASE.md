# VILLE — App Store release

> State file for the `app-store-release` skill. Claude reads it first and updates it at the end of every session.
> ✅ done · ⏳ in progress · 👉 your turn · ⬜ to do

## Quick reference

| | |
|---|---|
| Store name | `ville.` (suffix still open, see Decisions) |
| Home-screen name | `VILLE` (`PRODUCT_NAME`) |
| Bundle ID | `agu.VILLE` (permanent) |
| Apple ID (App Store Connect) | `6829207754` |
| SKU | `ville-ios` |
| Team | `56BK7T2JG7` (Alejandro Gómez Urrea) |
| Primary language | English (U.S.) |
| Listing locales | en-US (+ es-ES planned) |
| Devices / orientation | iPhone only, portrait |
| Minimum iOS | 26.2 |
| Version (build) | 1.0 (1) |
| Price | Free (Letterboxd ToS 6.9: no competing business) |
| Category | ⬜ (Entertainment, or Books?) |
| Privacy label | Data Not Collected (planned) |
| Privacy policy URL | ⬜ |
| Support URL | ⬜ |

## Decisions

- 2026-10-31 — Store name `ville.`, the same as the wordmark — the subtitle explains the app. Another app called "Ville • Find events near you." exists (events, Social Networking).
- 2026-10-31 — Keep bundle ID `agu.VILLE` — same style as `agu.culla`, and it was already in the project.
- 2026-10-31 — iPhone only, portrait, for 1.0 — reels are vertical and it means one screenshot set. iPad can come in a later version.
- 2026-10-31 — Screenshots captured automatically on the physical iPhone (XCUITest + demo mode), never the simulator.
- 2026-10-31 — Encryption exempt (`ITSAppUsesNonExemptEncryption = NO`): the app only uses HTTPS.
- Open — Name suffix for search (e.g. `ville. — Film Review Reader`). **No "Letterboxd" in the name, subtitle or keywords** (Risks 2). Decide in phase 3.

## 1. Foundations

- ✅ Program License Agreement accepted (2026-10-31)
- ✅ Paid Applications Schedule accepted (2026-10-31)
- ✅ Explicit App ID `agu.VILLE` registered (2026-10-31)
- ✅ App record created: `ville.`, Apple ID 6829207754 (2026-10-31)
- 👉 API key created and `asc auth status --validate` passes (`asc` 6.2.0 is installed)

## 2. Project readiness

- ✅ `audit.sh` has no ❌ (2026-10-31)
- ✅ Privacy manifest `VILLE/VILLE/PrivacyInfo.xcprivacy`: UserDefaults `CA92.1`, no tracking, no collected data
- ✅ Export compliance key
- ✅ iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait
- ✅ Release build compiles (Xcode 27.2, generic iOS, unsigned)
- ⬜ Third-party content: basis for the rights answer (Risks 1)
- ⬜ App finished (in progress)

## 3. Product page

- ⬜ Copy written in `store/metadata/` (en-US, es-ES) and approved
- ⬜ Privacy policy and support pages live (the repo is public, so GitHub Pages works; or your own site)
- ⬜ Metadata pushed (`asc metadata apply`)
- ⬜ Category, age rating, App Privacy, content rights, price and availability

## 4. Screenshots

- ⬜ Demo mode (`-StoreScreenshots`): in-memory store, our own demo reviews and members, no network, hidden status bar
- ⬜ `VILLEStoreShots` UI-testing target (you add it in Xcode) + capture test
- ⬜ Koubou template in the VILLE style (Source Serif 4, red full stop, plenty of space) + en/es captions
- ⬜ Validated and uploaded (required set: 1206 × 2622; optional 6.9" 1320 × 2868)

## 5. Build and submit

- ⬜ Final testing on the iPhone (by you)
- ⬜ Archive and upload
- ⬜ TestFlight check
- ⬜ Review notes (no sign-in; how to add a member; how the third-party content works)
- ⬜ Submitted (manual release)
- ⬜ Released

## Risks and open questions

1. **Letterboxd rights (Guideline 5.2.2 + "Content Rights").** VILLE shows other members' reviews from their public RSS feeds. The RSS route is the one Letterboxd offers (letterboxd.com/api-beta), and every reel credits the author and links back. But our March 2026 email is still unanswered. Write again before submitting (CLAUDE.md) and record the answer here, because it decides how we answer "Do you have the rights?".
2. **Trademark.** Never put "Letterboxd" in the name, subtitle or keywords (Guidelines 2.3.7 and 5.2.1, Letterboxd ToS 19). The description may say it factually ("reads the public RSS feeds of the Letterboxd members you choose"), plus "VILLE is not affiliated with Letterboxd."
3. **Other people's content (Guideline 1.2).** The reader picks whom to follow, can remove a member at any time, and each reel links to the original review, where it can be reported on Letterboxd. Explain this in the review notes.
4. **Art in screenshots.** TMDB posters and backdrops are fine in the app with attribution, not in marketing images. Use only art that is public domain in both the U.S. and the EU, or switch posters and backdrops off for the screenshots (VILLE's own "pure text" mode).
5. **iPhone Duo.** Screenshots are optional now and required from April 2027 for apps built with the iOS 27.1 SDK or later (we build with Xcode 27.2). Check how the layouts look on Duo before then.
6. **Name reservation.** Upload a first TestFlight build once the app runs, so the `ville.` record doesn't sit for months without a build.

## Log

- 2026-10-31 — Program License Agreement accepted (you). Registered `agu.VILLE`, created the `ville.` record (6829207754). Project set to iPhone-only and portrait, export-compliance key added, privacy manifest added, Release build OK. `asc` installed.
