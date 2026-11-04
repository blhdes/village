# VILLE: product page (review copy)

The files `asc` pushes live in `store/metadata/`, and they're the source of truth. This page explains them and adds the answers App Store Connect asks for outside those files. Nothing here has been sent to App Store Connect yet.

Status: en-US and es-ES **approved and sent** (2026-10-31). **Sent 2026-10-31 (your OK):** six more listings (de-DE, fr-FR, it, ja, pt-BR, zh-Hans), one per language the app speaks, plus an "In your language" section added to every description (en and es included). `asc metadata validate --dir store/metadata` → 0 errors. Dry run: 6 new app-info and 6 new version localizations, 2 updated descriptions (en, es), nothing deleted.

**Refreshed 2026-11-04, not sent yet:** description and promotional text in all 8 locales. «Add» became «Follow» (the app's verb since Search), two new sections (Search and Bookmarks), the Reading switches, backdrops described as optional (off by default), and the author's menu. Name, subtitle and keywords unchanged. `asc metadata validate` → 0 errors; dry run: 16 field updates, nothing added or deleted.

The six new listings are written natively, not word for word, with the words the app's own catalog uses (`Localizable.xcstrings`): Kritik, critique, recensione, レビュー, resenha, 影评. Tone as in the app: de *du*, fr *vous*, pt-BR *você*.

---

## Name and subtitle (the two strongest search fields)

| | en-US | es-ES |
|---|---|---|
| **Name** (30) | `ville. Film Review Reader` (25) | `ville. Críticas de cine` (23) |
| **Subtitle** (30) | `Movie reviews, one at a time` (28) | `Reseñas de pelis, una a una` (27) |

| | de-DE | fr-FR | it | ja | pt-BR | zh-Hans |
|---|---|---|---|---|---|---|
| **Name** (30) | `ville. Filmkritiken lesen` (25) | `ville. Critiques de films` (25) | `ville. Recensioni di film` (25) | `ville. 映画レビューを読む` (16) | `ville. Resenhas de filmes` (25) | `ville. 影评阅读器` (12) |
| **Subtitle** (30) | `Eine Kritik nach der anderen` (28) | `Avis de cinéma, un à la fois` (28) | `Critiche di cinema, una a una` (29) | `感想と批評を、ひとつずつ` (12) | `Críticas de cinema, uma a uma` (29) | `电影评论与观后感，一篇一篇读` (14) |

Why: the name keeps the wordmark first and adds the words people search for ("film review" / "críticas de cine"). The subtitle covers the other common words ("movie" / "reseñas", "pelis") and the idea of the app, the in-app tagline "Reviews, one at a time". Apple indexes the name, subtitle and keywords together, so each word appears only once across the three.

**No "Letterboxd"** in any of these fields: a third-party trademark there without written permission is a common rejection (Guidelines 2.3.7 and 5.2.1, Letterboxd ToS 19).

Alternatives if you prefer:
- `ville.` alone. Purest brand, but it gives up the name's search weight.
- `ville. Film Review Reels` (24). "Reels" sounds like Instagram, and fewer people search for it.

## Keywords (100 bytes, not visible on the page)

- en-US (97): `cinema,critic,cinephile,reels,rss,feed,diary,essay,reading,swipe,arthouse,classic,journal,minimal`
- es-ES (99): `película,cinéfilo,crítico,lector,reels,rss,feed,diario,ensayo,leer,deslizar,clásico,autor,texto`

- de-DE (100): `film,kino,rezension,cineast,filmfan,reels,rss,feed,tagebuch,essay,wischen,arthouse,klassiker,minimal`
- fr-FR (96): `cinéphile,ciné,reels,rss,flux,journal,carnet,essai,lecture,lire,glisser,classique,auteur,texte`
- it (95): `cinefilo,critico,reel,rss,feed,diario,saggio,lettura,leggere,scorrere,classico,autore,cineforum`
- ja (94 bytes, 40 characters): `映画評,シネフィル,名作,洋画,邦画,映画好き,鑑賞,日記,読書,RSS,リール`
- pt-BR (96): `cinéfilo,crítico,reels,rss,feed,diário,ensaio,leitura,ler,deslizar,clássico,autor,cult,texto`
- zh-Hans (95 bytes, 41 characters): `影迷,观影,影评人,文艺片,艺术电影,经典,老电影,随笔,日记,影视,RSS,极简`

Apple combines keywords with the name and subtitle ("film" + "critic" → "film critic"), so none repeats them. Brand names stay out. Counts are in bytes, Apple's limit: each Japanese or Chinese character takes 3, so those lists hold about 30 characters. (`asc` counts characters and would allow more, but staying under 100 bytes is safe either way.)

## Promotional text (170, can change any time without a review)

- en-US (136): *Follow the people whose film writing you love on Letterboxd and read their reviews as full-screen reels. One at a time, and with an end.*
- es-ES (126): *Sigue a quienes mejor escriben de cine en Letterboxd y lee sus reseñas como reels a pantalla completa. Una a una, y con final.*
- de-DE (144): *Folge den Menschen, deren Filmtexte du auf Letterboxd liebst, und lies ihre Kritiken als Reels im Vollbild. Eine nach der anderen, und mit Ende.*
- fr-FR (130): *Suivez les plumes de Letterboxd que vous aimez et lisez leurs critiques de films en reels plein écran. Une à une, et avec une fin.*
- it (156): *Segui le persone che scrivono di cinema su Letterboxd come piace a te e leggi le loro recensioni come reel a schermo intero. Una alla volta, e con una fine.*
- ja (68): *Letterboxdで好きな書き手をフォローして、その映画レビューを全画面のリールで読めます。ひとつずつ、そして終わりのあるフィードで。*
- pt-BR (143): *Siga as pessoas do Letterboxd cujos textos sobre cinema você adora e leia as resenhas delas em reels de tela cheia. Uma de cada vez, e com fim.*
- zh-Hans (51): *关注你在 Letterboxd 上最爱读的影评作者，以全屏方式阅读他们的影评。一篇一篇读，而且有终点。*

## Description (4000)

The full text is in `store/metadata/version/1.0/<locale>.json` (characters: en 2,847, es 3,187, de 3,453, fr 3,532, it 3,247, ja 1,641, pt-BR 3,151, zh-Hans 1,173). Every locale has the same structure:

1. **Reviews, one at a time.** + one sentence on what you do in the app. These are the only lines visible before "more".
2. A feed with an end (sessions, "Fin", Keep reading).
3. The words first (only written reviews, magazine layout, hide stars, spoilers covered, full reader).
4. **Read before you follow** (added 2026-11-04, replaces "Start in good company"): Search by username or profile link, reviews as reels before following, suggestions you can tap to read first.
5. **Keep the ones you love** (added 2026-11-04): bookmarks stay after unfollowing, double as a watchlist (swipe one away once you've seen the film), spoilers stay covered there.
6. In your language (the eight languages, one-tap translation on the iPhone, long-press to copy a passage).
7. Picked with care (unseen first, members take turns, the Reading switches: each review once, hide very short ones, pull to refresh).
8. The film around the words (posters, alternative posters, backdrops as an option since they're off by default, text-only, appearance).
9. Yours, on your iPhone (no account, no ads, no tracking, followed members and bookmarks stay on the device, saved library).
10. Credit where it's due (author + link back, share = link, the author's menu: profile, report on Letterboxd, unfollow).
11. Small print: RSS source for members you follow or search for, reviews belong to their authors, not affiliated with Letterboxd, TMDB notice.

In running text the app is called **VILLE**, as in Settings → About. "ville." with its full stop reads as the end of a sentence in the middle of a paragraph, so it stays for the name and the logo.

The app is localized (2026-10-31: en, es, de, fr, it, ja, pt-BR, zh-Hans), so the Spanish version no longer says the app is in English, and each of those languages has its own listing.

China mainland stays out of availability (no ICP number), so the Simplified Chinese listing reaches people whose iPhone is in Simplified Chinese in other storefronts (Singapore, Malaysia, and so on). The support and privacy pages stay in English with a Spanish section, the same URL for every locale.

---

## Everything else App Store Connect asks for

| Field | Proposal | Status |
|---|---|---|
| Copyright | `2026 Alejandro Gómez Urrea` | ready |
| Primary category | **Entertainment** (same as IMDb; Letterboxd adds it as its second) | ready |
| Secondary category | **Lifestyle** | ready |
| Price | Free (Letterboxd ToS 6.9) | ready |
| Availability | Every country **except China mainland**: new apps there need an ICP filing number | ready |
| Support URL | `https://blhdes.github.io/village/` (GitHub Pages, from `store/site/`, published with `store/publish-site.sh`) | ready |
| Privacy policy URL | `https://blhdes.github.io/village/privacy.html` (same) | ready |
| Marketing URL | None for now | |

### App Privacy (the "nutrition label")

**Data Not Collected.** Why it's true:
- No accounts, analytics, ads or crash SDKs. Nothing is sent to us.
- The app makes read-only requests that serve the screen in real time: Letterboxd RSS feeds for the members you follow or search for, TMDB for film images, and Google only when you tap a film title (it opens in Safari inside the app). Apple doesn't count that as "collection", because nobody keeps the data for us.
- It matches `PrivacyInfo.xcprivacy` (no tracking, no collected data) and the privacy policy draft.

### Content rights

"Does your app contain, show or access third-party content?" → **Yes** (other people's reviews from Letterboxd RSS, film images from TMDB).
"Do you have the necessary rights?" → **depends on Letterboxd's answer** (RELEASE.md → Risks 1). Follow-up sent 2026-10-31, waiting for an answer.

### Age rating (questionnaire, 2025 system: 4+ / 9+ / 13+ / 16+ / 18+)

The reviews are written by other people about any kind of film, so answer honestly:
- Profanity or crude humor, mature/suggestive themes, sexual content (in text), horror/fear themes, alcohol/drug references: **Infrequent/Mild**
- Violence: **Infrequent/Mild** (described in text)
- User-generated content: **yes**. It's read-only and only from members the reader chooses, who can be removed at any time.
- **Unrestricted web access: yes** (your choice, 2026-10-31). Tapping a title opens a Google search in Safari inside the app, and from there you can browse anywhere. It raises the rating: recent sources put web access at 16+ in the 2025 system, older ones at 18+. App Store Connect shows the final rating once the answers are sent.

For reference (iTunes data, 2026-10-31): Letterboxd is rated 17+ (old system), IMDb 12+.

### Review notes (English, for App Review)

The text App Review reads lives in `store/review-notes.txt` (the source of truth, sent by `store/apply-store-setup.sh`): no sign-in, how to search and follow, Settings, and how report and unfollow work from the reel (guideline 1.2).

Before submitting: untick "Sign-in required", add contact details, and choose **manual release**.
