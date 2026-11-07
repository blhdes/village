# VILLE: store screenshots plan

Status (2026-11-07): demo mode, capture test, Koubou config, captions and fonts ready, and the template checked with placeholder screens in all eight languages. Nothing captured yet: that needs the `VILLEStoreShots` target (you, in Xcode) and your go. Pipeline and rules: the `app-store-release` skill, phase 4.

## Sizes

- Your iPhone: **iPhone 13**, so raw captures are 1170 × 2532.
- Required set: iPhone 6.3" **1206 × 2622** (`koubou.yaml`). Optional later: 6.9" 1320 × 2868, the same template with `output_size: iPhone6_9`. Both come from the same captures, because the template places the screen on a canvas.
- iPhone Duo: later (required from April 2027).

## Shot list

The first three appear in search results, so they carry the pitch. Shots 5 to 7 go straight to the point: one plain screen each.

| # | Screen | Look | Caption en | Caption es |
|---|---|---|---|---|
| 1 | A reel: Nosferatu, backdrop, stars | dark | Film reviews, one at a time | Críticas de cine, una a una |
| 2 | A reel with a quote: Caligari, stars hidden | light | The words first | Primero, las palabras |
| 3 | Spoiler cover: The Last Laugh | dark | No spoilers until you tap | Sin spoilers hasta que toques |
| 4 | "Fin" card (with the plates), reached by swiping through the session | dark | A feed with an end | Un feed que termina |
| 5 | A reel already translated: A Trip to the Moon, "See original" under its date | light | Any review, in your language | Cualquier reseña, en tu idioma |
| 6 | People: Search, demo suggestions, Bookmarks (2), Following | light | Follow the writers you love | Sigue a quien mejor escribe |
| 7 | Settings: the preview and Look, Backdrops off | dark | Text only, if you like | Solo texto, si quieres |

The full reader (Sunrise, "Long reviews, in full") left to make room for the translation shot. It can come back as an 8th: a reader sheet over a reel.

### Captions in the other six languages

Same words the app uses in each language (Kritik, critique, recensione, レビュー, resenha, 影评). The source is `screenshots/captions.xcstrings`, where each caption also says where its line breaks (two lines at most, so it never reaches the screen).

| # | de-DE | fr-FR | it | ja | pt-BR | zh-Hans |
|---|---|---|---|---|---|---|
| 1 | Eine Filmkritik nach der anderen | Des critiques de films, une à une | Recensioni di film, una alla volta | 映画レビューを、ひとつずつ | Resenhas de filmes, uma de cada vez | 影评，一篇一篇读 |
| 2 | Zuerst die Worte | Les mots d’abord | Prima le parole | まず、言葉から | Primeiro, as palavras | 文字优先 |
| 3 | Keine Spoiler, bis du tippst | Aucun spoiler avant de toucher | Niente spoiler finché non tocchi | ネタバレは、タップで表示 | Sem spoilers até você tocar | 剧透，轻点才显示 |
| 4 | Ein Feed mit Ende | Un fil qui a une fin | Un feed che finisce | 終わりのあるフィード | Um feed que termina | 有终点的信息流 |
| 5 | Jede Kritik in deiner Sprache | Chaque critique dans votre langue | Ogni recensione nella tua lingua | どのレビューも、あなたの言語で | Qualquer resenha, no seu idioma | 每篇影评，都能用你的语言读 |
| 6 | Folge den Autoren, die du liebst | Suivez les plumes que vous aimez | Segui chi scrive come piace a te | 好きな書き手をフォロー | Siga quem você adora ler | 关注你喜欢的作者 |
| 7 | Nur Text, wenn du magst | Le texte seul, si vous préférez | Solo testo, se preferisci | 文字だけでも | Só texto, se preferir | 也可以只看文字 |

Changed on 2026-11-07 after the first render: de 1 (was "Filmkritiken, eine nach der anderen", three lines), fr 3 (was "Les spoilers, seulement si vous touchez", three lines), ja 3 (was "ネタバレは、タップするまで隠したまま"). Japanese and Chinese weren't checked by native speakers.

Captions are written without their final full stop: the template adds it (`{{stop}}`), "." or, in Japanese and Chinese, "。". Only shot 1's is **red**, like the wordmark: the dot keeps its meaning by being rare.

Until a locale has its own screenshots, App Store Connect shows the English ones on that listing.

## Design (`screenshots/templates/reel.html`)

Caption on top in Source Serif 4 Italic (opsz 60), the whole real screen below with rounded corners, a black or white background matching the shot (`look-dark.css`, `look-light.css`, `look-dark-red.css` for shot 1). No device frame and no decoration: VILLE prefers type and space. Japanese and Chinese captions use Noto Serif JP and SC, upright, slightly smaller. All three fonts are SIL OFL, in `screenshots/fonts/` with their licenses; the Noto files are cut down to the captions' characters (92 KB instead of 37 MB), so a new Japanese or Chinese caption needs them cut again (fontTools `pyftsubset --text=…` on the Google Fonts files). Preview with placeholder screens: `preview/layout-preview.png`.

## Demo content

All of it is in `screenshots/demo-content.md`: fictional members (each username checked: none exists on Letterboxd), reviews written by us in English and Spanish, seven silent films that are public domain in the U.S. and the EU, and the four film frames with their sources. Posters are off (poster artists often aren't public domain in the EU). Backdrops are frames from the films themselves.

## Demo mode in the app (built 2026-11-07)

Launched with `-StoreScreenshots <shot>` (the shot names in the list above, e.g. `1-reel`), a Debug build of VILLE:

- reads a fictional library kept in memory (`StoreDemoContent`), never the reader's own;
- fetches no feeds and asks TMDB nothing; the backdrops are the bundled frames;
- keeps Settings in a store of its own (`agu.VILLE.StoreDemo`), cleared at each launch and set per shot: appearance, Backdrops, Stars and likes; posters always off;
- shows the reels in a fixed order, the shot's film first, instead of chance;
- opens A Trip to the Moon translated, with a translation we wrote (a test run can't wait for Apple's language downloads);
- suggests fictional members in People, and hides the status bar.

| File | What it does |
|---|---|
| `VILLE/VILLE/StoreDemo/StoreDemo.swift` | The shots, their Settings, the hooks below |
| `VILLE/VILLE/StoreDemo/StoreDemoContent.swift` | Members, reviews (en, es), the Moon translation in 8 languages, suggestions |
| `VILLE/VILLE/StoreDemo/Frames/` | The four public-domain frames, 1280 × 720 |
| `VILLEApp.swift` | Demo library and Settings, the translation, `.storeDemo()` |
| `ReelSampler.swift` | Fixed order |
| `TMDBService.swift` | Frames instead of TMDB images |
| `SuggestedMember.swift` | Demo suggestions |
| `FeedViewModel.swift` | No refresh |
| `ReviewTranslator.swift` | `preload` for the translated reel |
| `ReelTopBar.swift`, `SessionEndView.swift` | Accessibility identifiers the test taps (`people`, `settings`, `fin`), the same in every language |
| Build settings | `EXCLUDED_SOURCE_FILE_NAMES = StoreDemo*.swift storedemo-*.jpg` in **Release**; every hook is `#if DEBUG` too. Checked: a Release build has no demo code and no frames |

## Running it

**Once, in Xcode (you):**

1. File → New → Target → **UI Testing Bundle**. Name `VILLEStoreShots`, team as the app's, target to be tested **VILLE**. Finish.
2. Xcode makes a folder `VILLE/VILLEStoreShots/` with two files. Tell Claude: it replaces them with `store/screenshots/StoreShots.swift` and checks that the test target is in the VILLE scheme.
3. On the iPhone 13: Developer Mode on, **Settings → Developer → Enable UI Automation** on, unlocked and connected.

**Each time:**

1. `store/screenshots/capture.sh` shows the plan (dry run). `capture.sh --go` runs the test once per language on the iPhone (it installs a test runner there, so only after your go) and saves `raw/<language>/<shot>.png`. One language: `capture.sh --go es-ES`.
2. Look at every raw capture.
3. `kou generate store/screenshots/koubou.yaml` writes `final/<language>/iPhone_17_-_Black_-_Portrait/<shot>.png` (the device name is only Koubou's label: frames are off).
4. Check: `magick identify -format "%f %wx%h %[channels]\n" store/screenshots/final/*/*/*.png` gives 1206 × 2622 and `srgb` (no alpha) for all 56.
5. Upload with `asc screenshots`, after your OK.

`raw/` and `final/` stay out of git: both are rebuilt by the two commands.
