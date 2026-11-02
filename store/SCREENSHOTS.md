# VILLE: store screenshots plan

Status: plan, demo content and template ready (2026-10-31). Nothing captured yet. Pipeline and rules: the `app-store-release` skill, phase 4.

## Sizes

- Your iPhone: **iPhone 13**, so raw captures are 1170 × 2532.
- Required set: iPhone 6.3" **1206 × 2622**. Optional: 6.9" **1320 × 2868**. Both are rendered from the same captures, because the template places the screen on a canvas, so the iPhone 13's size doesn't have to match.
- iPhone Duo: later (required from April 2027).

## Shot list

The first three appear in search results, so they carry the pitch.

| # | Screen | Look | Caption en | Caption es |
|---|---|---|---|---|
| 1 | A reel: Nosferatu, backdrop, stars | dark | Film reviews, one at a time | Críticas de cine, una a una |
| 2 | A reel with a quote: Caligari, stars hidden | light | The words first | Primero, las palabras |
| 3 | Spoiler cover: The Last Laugh | dark | No spoilers until you tap | Sin spoilers hasta que toques |
| 4 | "Fin" card (with the plates) | dark | A feed with an end | Un feed que termina |
| 5 | Full reader: Sunrise | light | Long reviews, in full | Las largas, enteras |
| 6 | People: demo members + demo suggestions | light | Follow the writers you love | Sigue a quien mejor escribe |

Optional 7: Settings → Look, with "Text only, if you like" / "Solo texto, si quieres".

### Captions in the other six languages (2026-10-31)

Same words the app uses in each language (Kritik, critique, recensione, レビュー, resenha, 影评).

| # | de-DE | fr-FR | it | ja | pt-BR | zh-Hans |
|---|---|---|---|---|---|---|
| 1 | Filmkritiken, eine nach der anderen | Des critiques de films, une à une | Recensioni di film, una alla volta | 映画レビューを、ひとつずつ | Resenhas de filmes, uma de cada vez | 影评，一篇一篇读 |
| 2 | Zuerst die Worte | Les mots d’abord | Prima le parole | まず、言葉から | Primeiro, as palavras | 文字优先 |
| 3 | Keine Spoiler, bis du tippst | Les spoilers, seulement si vous touchez | Niente spoiler finché non tocchi | ネタバレは、タップするまで隠したまま | Sem spoilers até você tocar | 剧透，轻点才显示 |
| 4 | Ein Feed mit Ende | Un fil qui a une fin | Un feed che finisce | 終わりのあるフィード | Um feed que termina | 有终点的信息流 |
| 5 | Lange Kritiken, vollständig | Les longues critiques, en entier | Le recensioni lunghe, per intero | 長いレビューも、最後まで | Resenhas longas, por inteiro | 长篇影评，完整阅读 |
| 6 | Folge den Autoren, die du liebst | Suivez les plumes que vous aimez | Segui chi scrive come piace a te | 好きな書き手をフォロー | Siga quem você adora ler | 关注你喜欢的作者 |
| 7 | Nur Text, wenn du magst | Le texte seul, si vous préférez | Solo testo, se preferisci | 文字だけでも | Só texto, se preferir | 也可以只看文字 |

Captions are written without their final full stop because the template adds it. Only shot 1 gets the **red** full stop, like the wordmark: the dot keeps its meaning by being rare (CLAUDE.md, big moments only). Open point for ja and zh-Hans: a Latin full stop after CJK text reads oddly, so decide in the template whether those captions end on "。" (and the red dot only on shot 1) or on no mark at all.

Until a locale has its own screenshots, App Store Connect shows the English ones on that listing.

## Design (`templates/reel.html`)

Caption on top in Source Serif 4 Italic, the whole real screen below with rounded corners, a black or white background matching the shot. No device frame and no decoration: VILLE prefers type and space. Preview with placeholder screens and Georgia standing in for the font: `preview/layout-preview.png`.

## Demo content

All of it is in `screenshots/demo-content.md`: fictional members (each username checked: none exists on Letterboxd), reviews written by us in English and Spanish, and seven silent films that are public domain in the U.S. and the EU. Posters are off (poster artists often aren't public domain in the EU). Backdrops are frames from the films themselves.

## Demo mode in the app (plan; the code waits for your OK)

| File | Change |
|---|---|
| `VILLE/VILLE/StoreDemo/StoreDemo.swift` (new) | `-StoreScreenshots YES` turns it on: an in-memory store with the demo members and reviews, fixed order and art, appearance from `-StoreAppearance`, language from the test run |
| `VILLE/VILLE/StoreDemo/Art/` (new) | The public-domain film frames |
| `VILLEApp.swift` | Uses the demo container when demo mode is on |
| `FeedViewModel.swift` | No network refresh or TMDB lookups in demo mode |
| `ReelQueue.swift`, `ReelSampler.swift` | Fixed order and fixed art picks in demo mode (today they're random) |
| `SuggestedMember.swift` | Demo suggestions instead of the 100 real ones |
| `ReelFeedView.swift` | Hidden status bar in demo mode |
| Build settings | `EXCLUDED_SOURCE_FILE_NAMES = StoreDemo/*` in **Release**, so none of it ships |
| `VILLEStoreShots` (new UI-test target, you create it in Xcode) | Walks through the six screens and saves each capture |

Backdrops are off by default since 2026-11-02, and the shots use public-domain frames as backdrops: demo mode turns `showBackdrops` on.

## Running it (later)

1. iPhone 13 connected and unlocked, Developer Mode on, **Settings → Developer → Enable UI Automation** on.
2. One run per language and look: `xcodebuild test … -destination "platform=iOS,id=<UDID from xcrun devicectl list devices>" -testLanguage es -testRegion ES …`. It installs a test runner on the iPhone, so it only happens after your go.
3. Extract the captures from the `.xcresult` into `screenshots/raw/<locale>/<look>/`.
4. `kou generate` writes `screenshots/final/<locale>/<size>/`, then a size and alpha check, then upload after your OK.
