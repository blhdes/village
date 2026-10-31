# VILLE: product page (review copy)

The files `asc` pushes live in `store/metadata/`, and they're the source of truth. This page explains them and adds the answers App Store Connect asks for outside those files. Nothing here has been sent to App Store Connect yet.

Status: **approved** (2026-10-31), not sent yet. `asc metadata validate --dir store/metadata` → 0 errors.

---

## Name and subtitle (the two strongest search fields)

| | en-US | es-ES |
|---|---|---|
| **Name** (30) | `ville. Film Review Reader` (25) | `ville. Críticas de cine` (23) |
| **Subtitle** (30) | `Movie reviews, one at a time` (28) | `Reseñas de pelis, una a una` (27) |

Why: the name keeps the wordmark first and adds the words people search for ("film review" / "críticas de cine"). The subtitle covers the other common words ("movie" / "reseñas", "pelis") and the idea of the app, the in-app tagline "Reviews, one at a time". Apple indexes the name, subtitle and keywords together, so each word appears only once across the three.

**No "Letterboxd"** in any of these fields: a third-party trademark there without written permission is a common rejection (Guidelines 2.3.7 and 5.2.1, Letterboxd ToS 19).

Alternatives if you prefer:
- `ville.` alone. Purest brand, but it gives up the name's search weight.
- `ville. Film Review Reels` (24). "Reels" sounds like Instagram, and fewer people search for it.

## Keywords (100 bytes, not visible on the page)

- en-US (97): `cinema,critic,cinephile,reels,rss,feed,diary,essay,reading,swipe,arthouse,classic,journal,minimal`
- es-ES (99): `película,cinéfilo,crítico,lector,reels,rss,feed,diario,ensayo,leer,deslizar,clásico,autor,texto`

Apple combines keywords with the name and subtitle ("film" + "critic" → "film critic"), so none repeats them. Brand names stay out.

## Promotional text (170, can change any time without a review)

- en-US (133): *Add the people whose film writing you love on Letterboxd and read their reviews as full-screen reels. One at a time, and with an end.*
- es-ES (126): *Añade a quienes mejor escriben de cine en Letterboxd y lee sus reseñas como reels a pantalla completa. Una a una, y con final.*

## Description (4000)

The full text is in `store/metadata/version/1.0/<locale>.json` (en 1,938 characters, es 2,269). Its structure:

1. **Reviews, one at a time.** + one sentence on what you do in the app. These are the only lines visible before "more".
2. A feed with an end (sessions, "Fin", Keep reading).
3. The words first (only written reviews, magazine layout, hide stars, spoilers covered, full reader).
4. Picked with care (unseen first, members take turns, pull to refresh).
5. The film around the words (backdrops, posters, alternative posters, text-only, appearance).
6. Start in good company (suggestions).
7. Yours, on your iPhone (no account, no ads, no tracking, saved library).
8. Credit where it's due (author + link back, share = link).
9. Small print: RSS source, reviews belong to their authors, not affiliated with Letterboxd, TMDB notice.

In running text the app is called **VILLE**, as in Settings → About. "ville." with its full stop reads as the end of a sentence in the middle of a paragraph, so it stays for the name and the logo.

The Spanish version says **the app is in English** (the interface isn't translated yet). If we localize it later (`/swift-localize`), remove that line.

---

## Everything else App Store Connect asks for

| Field | Proposal | Status |
|---|---|---|
| Copyright | `2026 Alejandro Gómez Urrea` | ready |
| Primary category | **Entertainment** (same as IMDb; Letterboxd adds it as its second) | ready |
| Secondary category | None, or **Lifestyle** | your choice |
| Price | Free (Letterboxd ToS 6.9) | ready |
| Availability | Every country **except China mainland**: new apps there need an ICP filing number | ready |
| Support URL | `https://blhdes.github.io/village/` (GitHub Pages, from `store/site/`, published with `store/publish-site.sh`) | ready |
| Privacy policy URL | `https://blhdes.github.io/village/privacy.html` (same) | ready |
| Marketing URL | None for now | |

### App Privacy (the "nutrition label")

**Data Not Collected.** Why it's true:
- No accounts, analytics, ads or crash SDKs. Nothing is sent to us.
- The app makes read-only requests that serve the screen in real time: Letterboxd RSS feeds for the usernames you add, TMDB for film images, and Google only when you tap a film title (it opens in Safari inside the app). Apple doesn't count that as "collection", because nobody keeps the data for us.
- It matches `PrivacyInfo.xcprivacy` (no tracking, no collected data) and the privacy policy draft.

### Content rights

"Does your app contain, show or access third-party content?" → **Yes** (other people's reviews from Letterboxd RSS, film images from TMDB).
"Do you have the necessary rights?" → **depends on Letterboxd's answer** (RELEASE.md → Risks 1). Write to them again before submitting.

### Age rating (questionnaire, 2025 system: 4+ / 9+ / 13+ / 16+ / 18+)

The reviews are written by other people about any kind of film, so answer honestly:
- Profanity or crude humor, mature/suggestive themes, sexual content (in text), horror/fear themes, alcohol/drug references: **Infrequent/Mild**
- Violence: **Infrequent/Mild** (described in text)
- User-generated content: **yes**. It's read-only and only from members the reader chooses, who can be removed at any time.
- **Unrestricted web access: 👉 your decision.** Tapping a title opens a Google search in Safari inside the app, and from there you can browse anywhere. The honest answer is probably "yes", which raises the rating. If you'd rather avoid that, the alternative is opening those searches in the Safari app outside VILLE. Reading would then leave the app, which goes against the vision.

For reference (iTunes data, 2026-10-31): Letterboxd is rated 17+ (old system), IMDb 12+.

### Review notes (draft, English, for App Review)

> VILLE has no accounts and no sign-in.
>
> To try it: tap the people icon (two figures) in the top bar and add any member from the "Suggested" list with the + button (or type a Letterboxd username, for example `812filmreviews`). Close the sheet: their recent written reviews appear as full-screen reels. Swipe up to read. After the session's last review a "Fin" card appears, with "Keep reading". The sliders icon (top bar) opens Settings, with appearance, session length and the poster, backdrop and rating toggles.
>
> Content: VILLE only shows reviews from the public RSS feed Letterboxd publishes for each member (letterboxd.com/<username>/rss/), and only for members the user adds. Every review credits its author and links to the original on Letterboxd ("View on Letterboxd"), where content can be reported. Removing a member in People deletes all of their reviews from the device. Film images come from the TMDB API, credited in Settings. No data leaves the device except these read-only requests.

Before submitting: untick "Sign-in required", add contact details, and choose **manual release**.
