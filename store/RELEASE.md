# VILLE: App Store release

> State file for the `app-store-release` skill. Claude reads it first and updates it at the end of every session.
> ✅ done · ⏳ in progress · 👉 your turn · ⬜ to do

## Quick reference

| | |
|---|---|
| Store name | `ville. Film Review Reader` (en) · `ville. Críticas de cine` (es), in App Store Connect (metadata dry run clean, 2026-11-07) |
| Home-screen name | `VILLE` (`PRODUCT_NAME`) |
| Bundle ID | `agu.VILLE` (permanent) |
| Apple ID (App Store Connect) | `6829207754` · version 1.0 id `7712a8d8-4ee9-4ffc-a6ed-f4f282b1d949` |
| SKU | `ville-ios` |
| Team | `56BK7T2JG7` (Alejandro Gómez Urrea) |
| `asc` profile | `Ale` (team key `DUFUT4RBBW`, Admin role, in the macOS keychain) |
| Primary language | English (U.S.) |
| Listing locales | en-US, es-ES, de-DE, fr-FR, it, ja, pt-BR, zh-Hans (one per app language) |
| Devices / orientation | iPhone only, portrait |
| Test device | iPhone 13 (raw captures 1170 × 2532) |
| Minimum iOS | 26.2 |
| Version (build) | 1.0 (1) |
| Price | Free (Letterboxd ToS 6.9: no competing business) |
| Category | Entertainment, secondary Lifestyle |
| Privacy label | Data Not Collected (proposed) |
| Privacy policy URL | ✅ https://blhdes.github.io/village/privacy.html |
| Support URL | ✅ https://blhdes.github.io/village/ |
| Pages | GitHub Pages, `gh-pages` branch, built from `store/site/` by `bash store/publish-site.sh` |

## Decisions

- 2026-10-31: Store record created as `ville.`, the same as the wordmark. Another app called "Ville • Find events near you." exists (events, Social Networking).
- 2026-10-31: Keep bundle ID `agu.VILLE`, the same style as `agu.culla` and already in the project.
- 2026-10-31: iPhone only, portrait, for 1.0. Reels are vertical and it means one screenshot set. iPad can come later.
- 2026-10-31: Screenshots captured automatically on the physical iPhone (XCUITest + demo mode), never the simulator.
- 2026-10-31: Encryption exempt (`ITSAppUsesNonExemptEncryption = NO`): the app only uses HTTPS.
- 2026-10-31: **No "Letterboxd" in the name, subtitle or keywords** (Risks 2). Name with a descriptive suffix instead, e.g. `ville. Film Review Reader`. No long dashes in any copy (your call).
- 2026-10-31: In prose the app is called VILLE, as in Settings → About. "ville." stays for the name and the logo.
- 2026-10-31: China mainland left out of availability (new apps there need an ICP filing number).
- 2026-10-31: China stays out for 1.0, checked again (your choice). Culla, Culla Music and doppio are on sale there because they barely use the internet. VILLE shows internet content from other people, the kind of app the ICP rule is for, and a filing needs a Chinese company or partner. In China, Letterboxd over HTTPS loads intermittently, TMDB is mixed and Google is blocked (GreatFire, 2026-10). To try later: `asc pricing availability edit --app 6829207754 --territory CHN --available true`.
- 2026-10-31: Listing copy approved as written in `store/METADATA.md`.
- 2026-10-31: Support and privacy pages on GitHub Pages (this repo is public), served from a `gh-pages` branch that holds only `store/site/`. Public contact: your personal Gmail (your choice, knowing it's public).
- 2026-10-31: Secondary category Lifestyle. Age rating: unrestricted web access **yes** (in-app Safari search stays, the rating goes up, probably 16+).
- 2026-10-31: Screenshot art: frames of public-domain films (your choice), posters off. Not text only.
- 2026-10-31: App Review contact: your personal email and phone, saved in `store/contact.env` (gitignored, never in git).
- 2026-10-31: One store listing per app language (8). Keywords kept under 100 bytes, so Japanese and Chinese hold about 30 characters.
- 2026-10-31: The pages' favicon, home-screen icon and link-preview image are the real app icon, exported from `AppIcon.icon` with Icon Composer's `ictool` (never redrawn).
- 2026-11-07: Seven screenshots. A translation shot joins as 5 ("Any review, in your language"): one reel, already translated, with its "See original" note, rather than a before and after (shots 5 to 7 straight to the point, your call). The full reader shot left to make room; Settings → Look ("Text only, if you like") is 7. The translated text is ours, written as Translation would give it, because a test run can't wait for Apple's language downloads.
- 2026-11-07: Captions end on "。" in Japanese and Chinese, "." elsewhere; only shot 1's is red. Japanese and Chinese captions use Noto Serif JP/SC (OFL), upright, subset to the captions' characters.
- 2026-11-07: Posters in the screenshots (your call: they're on by default, so most shots show one). Made from other frames of the same public-domain films, cropped to 2:3, never the real posters (their artists often aren't public domain in the EU). Shots 1, 2 and 5; shot 3 has none (The Last Laugh has no video on Commons) and shot 7 stays text only.
- 2026-11-07: Backdrops in half the reel shots only, the dark ones (1 and 3); the light ones (2 and 5) show VILLE without them (your call: it looks good both ways). The Caligari and Moon backdrop frames stay bundled, unused for now.
- 2026-11-07: Settings → Look's appearance pages show a sun, a moon and both, not the wordmark (your call: the brand isn't a control).
- 2026-11-07: The wordmark's dot never breathes or blinks (your call): breathing belongs to the loading dot. While it breathes (pull-to-refresh, first reviews arriving), the wordmark's dot fades out and comes back after. Refreshes nobody waits on show nothing.
- 2026-11-02: New logo from a logo study (your pick): Source Serif 4 Italic, weight 670, a bigger red full stop, for both the wordmark and the icon (`brand/export_marks.py`). Pages' favicon, home-screen icon and link-preview image exported again from the new `AppIcon.icon` on 2026-11-04 (Icon Composer's own `ictool`, inside Icon Composer.app, converted to sRGB so every browser and link preview shows the same red); republished the same day. The store screenshots aren't made yet, so they'll show the new logo.
- 2026-11-07: The icon's light background is pure white (#FFFFFF) instead of the warm off-white #F5F0EB (your call). In dark, the "v" is pure white too, on the same #171717. Pages' favicon, home-screen icon and link-preview image exported again with `ictool`; the link preview now sits on a neutral light gray (#F0F0F0), since a white icon on white loses its outline. Republished the same day.

## 1. Foundations

- ✅ Program License Agreement accepted (2026-10-31)
- ✅ Paid Applications Schedule accepted (2026-10-31)
- ✅ Explicit App ID `agu.VILLE` registered (2026-10-31)
- ✅ App record created: `ville.`, Apple ID 6829207754 (2026-10-31)
- ✅ API key `asc-cli` created by you, stored by `asc`, `asc auth status --validate` → works (2026-10-31)

## 2. Project readiness

- ✅ `audit.sh` has no ❌ (2026-10-31)
- ✅ Privacy manifest `VILLE/VILLE/PrivacyInfo.xcprivacy`: UserDefaults `CA92.1`, file sizes `C617.1` (Settings → Storage, added 2026-10-31), no tracking, no collected data
- ✅ Export compliance key
- ✅ iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait
- ✅ Release build compiles (Xcode 27.2, generic iOS, unsigned)
- 👉 Third-party content: basis for the rights answer (Risks 1)
- ⏳ Privacy policy and a way to contact you inside the app (guidelines 5.1.1 and 1.5): Settings → About links to the privacy and support pages (2026-11-02, in the code, waiting for your iPhone test)
- ⏳ App finished (you). The plan for the rest of 1.0 is in the vault (`Projects/village-swift/village-swift.md`, Next steps)

## 3. Product page

- ✅ Copy written in `store/metadata/` (en-US, es-ES) and approved (2026-10-31), including the support and privacy URLs. `asc metadata validate` → 0 errors. Not sent yet.
- ✅ Privacy policy and support pages online at https://blhdes.github.io/village/ (2026-10-31). To change them: edit `store/site/`, commit, `bash store/publish-site.sh`
- ✅ `store/apply-store-setup.sh --go` sent (2026-10-31, your OK): copy en/es with support and privacy URLs, categories, copyright, manual release, free price, availability without China, age rating, App Review contact and notes. Every call succeeded. Re-run it after changing any of those files.
- ✅ App Privacy "Data Not Collected" published in App Store Connect (2026-10-31, Chrome)
- ✅ Six more listings (de-DE, fr-FR, it, ja, pt-BR, zh-Hans) + "In your language" section in every description, sent with `asc metadata apply` (2026-10-31, your OK). A dry run afterwards shows no differences. To change them: edit `store/metadata/`, then the same command.
- ✅ Content rights: `USES_THIRD_PARTY_CONTENT`, rights declared (your call, 2026-11-07, without Letterboxd's answer; basis in Risks 1): `asc apps content-rights edit --uses-third-party-content=true`
- ✅ Description and promotional text refreshed in all 8 languages and sent (2026-11-04, your OK): «Follow» instead of «Add», Search and Bookmarks sections, the Reading switches, backdrops as an option, the author's menu. A dry run afterwards shows no differences.

`asc validate` (2026-10-31): 3 blocking items left: content rights (waits for Letterboxd; never answer "does not use third-party content", which `asc` suggests), screenshots, build. App Privacy is published (the API can't check it, so `asc` still shows an info line).

## 4. Screenshots

- ✅ Plan: `store/SCREENSHOTS.md` (seven shots, captions in 8 languages, 2026-11-07)
- ✅ Demo content: `store/screenshots/demo-content.md`. Fictional members (usernames checked: none exist), our own reviews, public-domain films
- ✅ Template `store/screenshots/templates/reel.html` + `koubou.yaml` + `captions.xcstrings`, rendered with placeholder screens in all 8 languages (2026-11-07)
- ✅ Demo mode in the app: `VILLE/VILLE/StoreDemo/`, Debug only, left out of Release (checked: no demo code or frames in a Release build) (2026-11-07)
- ✅ Koubou 0.21 installed; Source Serif 4 and Noto Serif JP/SC (OFL) in `store/screenshots/fonts/`; four public-domain film frames from Wikimedia Commons (2026-11-07)
- ✅ Capture test `store/screenshots/StoreShots.swift` + `store/screenshots/capture.sh` (dry run checked) (2026-11-07)
- ✅ `VILLEStoreShots` UI Testing Bundle target, created in Xcode; the test moved to `VILLE/VILLEStoreShots/StoreShots.swift`, minimum iOS 26.2, builds (2026-11-07)
- ✅ First capture on the iPhone, English only (`capture.sh --go en-US`, your OK): test passed, 7 raw screens, composed and checked at 1206 × 2622 (2026-11-07)
- ✅ All 8 languages captured on the iPhone (your OK) and composed: 56 images, 1206 × 2622, no alpha, checked one by one (2026-11-07)
- ✅ Upload dry run: 7 per language into `APP_IPHONE_61`, all 8 listings found, nothing there yet (2026-11-07)
- ✅ Uploaded (your OK, 2026-11-07): 8 languages × 7 in `APP_IPHONE_61`, order checked, three duplicates from upload timeouts removed (de 1, fr 5 twice)
- ⬜ Optional 6.9" set (1320 × 2868), later

## 5. Build and submit

- ✅ Final testing on the iPhone (you, 2026-11-07: OK)
- ✅ Archive and upload 1.0 (1) (2026-11-07, your OK). Archive: `xcodebuild … -configuration Release -archivePath store/build/VILLE.xcarchive archive -allowProvisioningUpdates`. Upload: `PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH" xcodebuild -exportArchive -archivePath store/build/VILLE.xcarchive -exportOptionsPlist store/ExportOptions.plist -exportPath store/build/export -allowProvisioningUpdates`. The PATH matters: with Homebrew's rsync first, the export fails with "Copy failed" (`--extended-attributes: unknown option`, Apple's openrsync and Homebrew's rsync 3.x don't talk)
- ⏭️ TestFlight check skipped for 1.0: you tested the same code on the iPhone (Debug) and wanted to submit the same day
- ✅ Review notes sent (2026-11-04, your OK): `store/review-notes.txt` (Search, Follow, Reading options, report and unfollow from the reel). Re-send with `asc review details-create … --if-exists update` after changing them
- ✅ Submitted for review, manual release (your OK, 2026-11-07 21:34): build `e096305f-592e-4790-9582-9cfb4565933c`, submission `9c6cb01a-bf28-4053-b610-2dd69b3fef61`. Status: `asc review status --app 6829207754`
- 👉 Released: after approval, when you say so (`asc versions release --version-id 7712a8d8-4ee9-4ffc-a6ed-f4f282b1d949 --confirm`)

## Risks and open questions

1. **Letterboxd rights (Guideline 5.2.2 + "Content Rights").** VILLE shows other members' reviews from their public RSS feeds. RSS is the route Letterboxd offers (letterboxd.com/api-beta), and every reel credits the author and links back. Emails to api@letterboxd.com, one thread: 2026-01-09 (API access for a web app, never answered) and 2026-10-31 (follow-up describing VILLE and its RSS use, asking for a written OK for Apple's content rights question). You expect no answer. Record any answer here. 2026-11-07: Content Rights answered in App Store Connect as "uses third-party content" with the rights declared (your call), on this basis: public RSS offered by Letterboxd, the author credited and linked on every reel, nothing stored beyond the reader's device.
2. **Trademark.** Never "Letterboxd" in the name, subtitle or keywords (Guidelines 2.3.7 and 5.2.1, Letterboxd ToS 19). The description says it factually, plus "VILLE is not affiliated with Letterboxd".
3. **Other people's content (Guideline 1.2).** The reader picks whom to follow, removing a member deletes their reviews, and each reel links to the original, where it can be reported. Since 2026-11-02 the reel itself covers report and block: tapping "Review by …" offers Report on Letterboxd and Unfollow (asks first; bookmarks stay). The review notes say so (updated locally the same day, with the "Add" button and bookmarks fixed). Sent 2026-11-04.
4. **Age rating: unrestricted web access.** Decided 2026-10-31: answer "yes" (Safari inside the app reaches any site). The rating goes up, probably to 16+.
5. **Art in screenshots.** TMDB art is fine in the app, not in marketing. Decided 2026-10-31: posters off, backdrops from frames of public-domain films.
6. **Localized app (2026-10-31).** The app ships in en, es, de, fr, it, ja, pt-BR and zh-Hans, so the "La app está en inglés" line left the Spanish listing. All eight languages have listings in App Store Connect (2026-10-31). Until each has its own screenshots, App Store Connect shows the English ones there. The translations weren't checked by native speakers: worth a look for ja and zh-Hans before submitting.
7. **iPhone Duo.** Screenshots required from April 2027 for iOS 27.1+ SDK builds.
8. **Name reservation.** Upload a first TestFlight build once the app runs.
9. **Public repo.** Contact details go in `store/contact.env` (gitignored). No UDIDs or keys in git.
10. **Copy and translate (added 2026-10-31).** Review text can be selected and copied, and translated into the reader's language (VILLE's own, if one was picked in iOS Settings, else the iPhone's) with Apple's Translation framework, on the device. Nothing is stored, synced or sent, and Share stays a link, so App Privacy ("Data Not Collected") and the privacy page stay true. If Letterboxd answers the email thread, check they're fine with on-device translation (it works like Safari's Translate on their site).
11. **Search (built 2026-11-03).** Opening any member's feed by username or link, without following, is still RSS only, one member at a time and on demand (ToS 6.8 and 6.11 stay fine: no index, no scraping). Reviews of a member found but not followed are deleted at the next launch, bookmarks apart. The privacy page says so and that VILLE fetches the feed of a member you search for (updated locally, effective 3 November 2026; set the day it goes live if later). Their feed's byline menu keeps Report on Letterboxd (guideline 1.2). Review notes sent and pages published 2026-11-04 (privacy effective 4 November 2026).

## Log

- 2026-10-31: Agreements accepted (you). Registered `agu.VILLE`, created the `ville.` record (6829207754). Project set to iPhone only and portrait, export-compliance key and privacy manifest added, Release build OK. Commit `89c2067`.
- 2026-10-31: API key connected to `asc` (profile Ale). Listing copy en/es written and validated. Privacy and support pages drafted. `apply-store-setup.sh` + review notes ready (dry run only, nothing sent). Screenshot plan, demo content and template done. Pending list in the vault: `Areas/Claude/Skills/Docs/app-store-release.md`.
- 2026-10-31: Copy approved. Branch pushed. Support and privacy pages published on GitHub Pages (`store/publish-site.sh`, `gh-pages` branch), URLs added to `store/metadata/`.
- 2026-10-31: Lifestyle + web access "yes" set in `apply-store-setup.sh`. Pages got the app icon as favicon, home-screen icon and link-preview image.
- 2026-10-31: Contact saved in `store/contact.env`. `apply-store-setup.sh --go` sent everything the API can set. `asc validate`: 35 → 3 blocking (content rights, screenshots, build).
- 2026-10-31: App Privacy published: Data Not Collected.
- 2026-10-31: Follow-up email sent to Letterboxd (api@letterboxd.com, same thread as January).
- 2026-10-31: Screenshots will use public-domain film frames.
- 2026-10-31: App localized into es, de, fr, it, ja, pt-BR, zh-Hans (`Localizable.xcstrings`). Settings → Language opens iOS's per-app language page. Spanish listing line about an English-only app removed.
- 2026-10-31: Product page written for de-DE, fr-FR, it, ja, pt-BR and zh-Hans (`store/metadata/`, `METADATA.md`), "In your language" section added to every description, screenshot captions for the six languages in `SCREENSHOTS.md`. Validated and dry-run only: nothing sent.
- 2026-10-31: Six listings sent and the en/es descriptions updated (`asc metadata apply`, your OK). App Store Connect now has 8 locales. `asc validate`: still 3 blocking (content rights, screenshots, build), nothing new.
- 2026-11-02: Settings redesigned: a live preview of the reel on screen, Appearance as three pages, monochrome icons, the session length in one tap (new Reading section), and About with the privacy policy, help and contact, a rating link and the version. Built, not yet tested on the iPhone. Plan for the rest of 1.0 agreed and saved in the vault.
- 2026-11-02: New wordmark and icon (Source Serif 4 Italic, weight 670, dot 140%), exported from the font by `brand/export_marks.py`, which first reproduced the old icon point for point. Built, not yet tested on the iPhone. Site icons wait for that test.
- 2026-11-02: Unfollow from the reel: tapping "Review by …" offers the author's profile, Report on Letterboxd and Unfollow (asks first, the feed moves on before the member goes). ReelQueue.sync now finds the reel on screen by id after reels leave. Review notes updated locally, not sent. Built, not yet tested on the iPhone. The support page could mention the byline menu when the site icons are redone.
- 2026-11-02: boxd.it short links work in the add field (`LetterboxdLink`: one HEAD request to boxd.it, reads the redirect only, never follows it). Film and journal links get their own message. Privacy page updated locally (boxd.it named, effective 2 November 2026; set the day it goes live if later). 👉 Publish with the site icons after your OK.
- 2026-11-02: Hide very short reviews (Settings → Reading, off by default, under 10 words). Support FAQ and privacy page updated locally. Built, not yet tested on the iPhone.
- 2026-11-02: Rating request on Fin cards (Apple's `requestReview`, which never appears in TestFlight): the third one, then up to three more, at least a month apart, the fourth a year after the first (iOS shows it at most three times in 365 days). Privacy page updated locally (finished sessions and ask dates stay on the iPhone). Built, not yet tested on the iPhone. 👉 Publish the pages with the site icons after your OK.
- 2026-11-02: Show each review once (Settings → Reading, off by default): sessions never bring back a review already shown; with nothing new left, the Fin card drops Keep reading and the feed says "Nothing new yet". Support FAQ and privacy page updated locally. Built, not yet tested on the iPhone.
- 2026-11-02: People's Bookmarks row got a monochrome icon, like the Settings rows. Built, not yet tested on the iPhone.
- 2026-11-02: Backdrops off by default (your call). 👉 The screenshot plan uses public-domain frames as backdrops, so the demo mode must turn Backdrops on. Built, not yet tested on the iPhone.
- 2026-11-02: Uncovered spoilers are saved on the review: they stay uncovered on the reel, in Bookmarks and after VILLE quits (before, only until it quit). Privacy page updated locally. Built, not yet tested on the iPhone.
- 2026-11-02: Bookmarks double as a watchlist: swipe a row left in the list to remove it, after a confirmation. Support FAQ updated locally. Built, not yet tested on the iPhone.
- 2026-11-02: Docs brought up to date with this session (support FAQ: the Suggested button is "Add", spoilers, bookmark swipe; review notes: Reading options; screenshot plan: demo mode turns backdrops on; README; vault Phase 07). Nothing published or sent. Next before the demo build: translation intro, a stronger brand red, Search, the light/dark redraw bug in Settings.
- 2026-11-03: Search, from the search study (your pick: the proposal, with reviews read in a member's feed not counting as shown). People's field searches by username or link (one RSS request when sent) and shows the member found with «Read their reviews» and «Follow»; tapping a name in Suggested or Following opens their reviews. Their feed opens full screen, newest first, and ends on their name with the red full stop. «Add» became «Follow». Privacy page, support FAQ and review notes updated locally, nothing published or sent. Built, not yet tested on the iPhone.
- 2026-11-03: Confirmations open beside what they ask about: removing a bookmark points at its row (it opened at the top of the list), and the reel's Unfollow at «Review by …» instead of the whole header. Following's swipe says «Unfollow» instead of the system's «Delete» and asks first, like the reel (before, a long swipe deleted the member and their reviews at once). Built, not yet tested on the iPhone.
- 2026-11-03: Tested on the iPhone: the confirmations open beside their row. Fixed a flash after confirming: the row went at once, taking its question with it still marked open, so iOS showed the question again for an instant over the empty place. Rows now ask through `rowConfirmation`, which closes the question, then removes the row. Built, the fix not yet tested on the iPhone.
- 2026-11-04: The reel's buttons rest on the bottom safe area (`e624938`, pushed). Store description and promotional text refreshed in 8 languages, site icons exported again from the new icon, privacy page dated 4 November 2026. Sent with your OK: the 8 descriptions and promotional texts (`asc metadata apply`) and the review notes (`asc review details-create --if-exists update`, only those two, so price and availability weren't touched). Pages published.
- 2026-11-07: Screenshot pipeline built, nothing captured or sent. Demo mode (`VILLE/VILLE/StoreDemo/`, Debug only): `-StoreScreenshots <shot>` opens a fictional library in memory, fixed reels and frames, its own Settings, no feeds fetched, no status bar; Release builds leave it out. Capture test and `capture.sh` (one run per language on the iPhone, attachments saved as `raw/<language>/<shot>.png`). Koubou config, captions in 8 languages and fonts; rendered with placeholders and checked in every language. Four frames from Wikimedia Commons (Nosferatu, Caligari, A Trip to the Moon from the films' public-domain videos; The Last Laugh from a 1925 book's still). 👉 Next: you create the `VILLEStoreShots` target in Xcode, then the first capture after your OK.
- 2026-11-07: `VILLEStoreShots` test target made in Xcode (you); minimum iOS set to the app's 26.2 (Xcode had 27.2, the iPhone runs 26.6). First English capture on the iPhone with your OK: 7 screens, composed by Koubou. Fixes after looking at them: Settings switches gray in dark mode (the white knob vanished on a white switch), 13 English texts with ’, the appearance pages with a sun and a moon, the wordmark's dot no longer breathes (it steps aside for the loading dot), posters in demo mode from film frames. Built, not yet tested on the iPhone. Nothing sent to Apple.
- 2026-11-07: Backdrops on shots 1 and 3 only (your call). All 8 languages captured: the first full run came out in English everywhere but the captions, because `capture.sh` passed the language as build settings instead of `TEST_RUNNER_` environment variables; fixed, and the test no longer falls back to English without them. The search field's placeholder was cut off in 6 languages: shortened in es, de, fr, it, pt-BR, ja, zh-Hans (e.g. "Usuario o enlace de Letterboxd"). 56 images composed and checked; upload dry run clean. Nothing sent to Apple.
- 2026-11-07: Content rights declared (your call). Build 1.0 (1) archived, uploaded and processed (valid in 2 minutes). Screenshots uploaded in all 8 languages. `asc validate`: only "no build attached". Submitted for review with manual release: Waiting for Review. Commits pushed and `main` fast-forwarded to `8de6455` (your OK).
