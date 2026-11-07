//
//  StoreDemoContent.swift
//  VILLE
//
//  The library the store screenshots show (store/screenshots/demo-content.md):
//  fictional members (each username checked: no such Letterboxd member),
//  reviews we wrote, and seven silent films in the public domain in the
//  U.S. and the EU. Debug builds only, like the rest of `StoreDemo`.
//
//  English and Spanish screenshots read reviews in their own language;
//  the other six read the English ones, as most Letterboxd reviews are,
//  so every reel offers "Translate". In every language, A Trip to the
//  Moon is written in another one and opens translated.
//

#if DEBUG
import Foundation
import SwiftData

enum DemoFilm: String, CaseIterable {
    case nosferatu, caligari, lastLaugh, sunrise, moon, movieCamera, nanook

    var title: String {
        switch self {
        case .nosferatu: "Nosferatu"
        case .caligari: "The Cabinet of Dr. Caligari"
        case .lastLaugh: "The Last Laugh"
        case .sunrise: "Sunrise"
        case .moon: "A Trip to the Moon"
        case .movieCamera: "Man with a Movie Camera"
        case .nanook: "Nanook of the North"
        }
    }

    var year: Int {
        switch self {
        case .nosferatu: 1922
        case .caligari: 1920
        case .lastLaugh: 1924
        case .sunrise: 1927
        case .moon: 1902
        case .movieCamera: 1929
        case .nanook: 1922
        }
    }

    /// Letterboxd's film slug, for the review's (fictional) link.
    var slug: String {
        switch self {
        case .nosferatu: "nosferatu"
        case .caligari: "the-cabinet-of-dr-caligari"
        case .lastLaugh: "the-last-laugh"
        case .sunrise: "sunrise-a-song-of-two-humans"
        case .moon: "a-trip-to-the-moon"
        case .movieCamera: "man-with-a-movie-camera"
        case .nanook: "nanook-of-the-north"
        }
    }

    /// A frame from the film, bundled in StoreDemo/Frames, for the films
    /// a screenshot shows with its backdrop.
    var hasFrame: Bool {
        switch self {
        case .nosferatu, .caligari, .lastLaugh, .moon: true
        case .sunrise, .movieCamera, .nanook: false
        }
    }

    /// Newest first, a few days apart, so dates read the same on every run.
    var published: DateComponents {
        let day = switch self {
        case .nosferatu: 30
        case .caligari: 29
        case .lastLaugh: 27
        case .sunrise: 25
        case .moon: 24
        case .movieCamera: 21
        case .nanook: 18
        }
        return DateComponents(year: 2026, month: 10, day: day, hour: 21)
    }
}

struct DemoMember {
    let username: String
    let name: String

    static let june = DemoMember(username: "juneokafor", name: "June Okafor")
    static let theo = DemoMember(username: "theovarga", name: "Theo Varga")
    static let margit = DemoMember(username: "margitsandoval", name: "Margit Sandoval")
    static let ines = DemoMember(username: "inesmarlowe", name: "Inés Marlowe")
    static let paco = DemoMember(username: "pacolindqvist", name: "Paco Lindqvist")
    static let clara = DemoMember(username: "claraibarra", name: "Clara Ibarra")
}

struct DemoReview {
    let film: DemoFilm
    let author: DemoMember
    let rating: Double
    var liked = false
    var rewatch = false
    var spoiler = false
    let html: String
}

/// A Trip to the Moon as written, and the translation the reel shows.
struct DemoMoon {
    let review: DemoReview
    let translation: [ReviewBlock]

    var html: String { review.html }
}

struct StoreDemoContent {
    /// VILLE's interface language: "en", "es", "de"…
    let language: String

    static func reviewID(_ film: DemoFilm) -> String { "storedemo-\(film.rawValue)" }

    private var isSpanish: Bool { language == "es" }

    /// Six reviews in the reader's language (English for the six
    /// languages without their own set), plus A Trip to the Moon.
    var reviews: [DemoReview] {
        (isSpanish ? Self.spanish : Self.english) + [moon.review]
    }

    /// Written in Spanish for English readers, in English for everyone
    /// else, and shown translated into the interface's language.
    var moon: DemoMoon {
        let original = language == "en" ? Self.moonSpanish : Self.moonEnglish
        let paragraphs = Self.moonTranslations[language] ?? Self.moonTranslations["en"] ?? []
        return DemoMoon(review: original, translation: paragraphs.map { .paragraph(AttributedString($0)) })
    }

    var suggestions: [SuggestedMember] {
        isSpanish
            ? [SuggestedMember("luciaabend", "Lucía Abend", language: "es"),
               SuggestedMember("tomaskovac", "Tomás Kovač", language: "es"),
               SuggestedMember("elenarauch", "Elena Rauch", language: "es")]
            : [SuggestedMember("adawhitlock", "Ada Whitlock"),
               SuggestedMember("rafaelosei", "Rafael Osei"),
               SuggestedMember("minacastellar", "Mina Castellar")]
    }

    /// Two bookmarks, for the People screen's Bookmarks row.
    private static let bookmarked: Set<DemoFilm> = [.movieCamera, .nanook]

    // MARK: Saving

    func insert(into context: ModelContext, for shot: StoreShot) {
        let calendar = Calendar(identifier: .gregorian)
        var members: [String: DemoMember] = [:]

        for review in reviews {
            let film = review.film
            let published = calendar.date(from: film.published) ?? .now
            let parsed = ParsedReview(
                id: Self.reviewID(film),
                username: review.author.username,
                authorName: review.author.name,
                link: "https://letterboxd.com/\(review.author.username)/film/\(film.slug)/",
                publishedAt: published,
                watchedOn: calendar.date(byAdding: .day, value: -1, to: published),
                filmTitle: film.title,
                filmYear: film.year,
                tmdbID: nil,
                rating: review.rating,
                liked: review.liked,
                isRewatch: review.rewatch,
                containsSpoilers: review.spoiler,
                reviewHTML: review.html,
                wordCount: ReviewLength.words(in: ReviewHTML.plainText(from: review.html))
            )
            let saved = Review(from: parsed)
            // Art is settled: no TMDB lookups, no skeletons.
            saved.artFetched = true
            saved.posterPaths = []
            saved.backdropPaths = film.hasFrame ? ["/storedemo/\(film.rawValue)"] : []
            if Self.bookmarked.contains(film) {
                saved.bookmarkedAt = published
            }
            // The Fin card counts what's left unread: after this session,
            // nothing, on every run.
            if shot == .fin {
                saved.lastShownAt = published
            }
            context.insert(saved)
            members[review.author.username] = review.author
        }

        // People lists the newest first: these dates put the names in
        // alphabetical order.
        for (index, member) in members.values.sorted(by: { $0.name < $1.name }).enumerated() {
            let added = calendar.date(from: DateComponents(year: 2026, month: 9, day: 30 - index)) ?? .now
            context.insert(FollowedUser(username: member.username, displayName: member.name, addedAt: added))
        }
    }

    // MARK: English

    private static let english: [DemoReview] = [
        DemoReview(film: .nosferatu, author: .june, rating: 4.5, liked: true, html: """
            <p>Murnau films the plague as a slow arrival: a ship with no one at the wheel, a shadow that climbs the stairs before the body does.</p>\
            <p>A hundred years on, the most frightening thing here is still the patience. Orlok never hurries. <i>He doesn’t have to.</i></p>
            """),
        DemoReview(film: .caligari, author: .theo, rating: 4, rewatch: true, html: """
            <p>Every street bends as if it were trying to get away from you. The painted shadows do half the acting, and the other half is Conrad Veidt standing very, very still.</p>\
            <blockquote><p>You must become Caligari.</p></blockquote>\
            <p>The frame story still lands like a trapdoor. I knew it was coming and it got me anyway.</p>
            """),
        DemoReview(film: .lastLaugh, author: .june, rating: 4, spoiler: true, html: """
            <p>The film’s only title card apologizes for the ending it’s about to give you. The writer couldn’t bear to leave the old doorman in the washroom, so he inherits a fortune instead.</p>\
            <p>It’s a cheat, Murnau knows it’s a cheat, and the joke is on us for wanting it so badly.</p>
            """),
        DemoReview(film: .sunrise, author: .margit, rating: 5, liked: true, html: """
            <p>I came for the famous tracking shot through the marsh and stayed for the tram. The city sequence is pure joy: two people who nearly lost each other, learning again how to be silly in public.</p>\
            <p>Murnau trusts faces more than title cards. There are long stretches with no text at all and you never feel lost, because Janet Gaynor’s face carries every line.</p>\
            <p>What stays with me is how the film refuses to be only one thing. It’s a thriller for twenty minutes, a romantic comedy for forty, a storm at sea for ten, and none of it feels like a seam.</p>\
            <p>The ending lights the village with lanterns and you realize the whole film has been about light: moonlight on the marsh, neon in the city, the sun coming up over a bed.</p>\
            <p><b>Subtitle:</b> <i>A Song of Two Humans.</i> It earns every word of it.</p>
            """),
        DemoReview(film: .movieCamera, author: .margit, rating: 4.5, html: """
            <p>A city wakes up, works, plays and goes to sleep, and the camera refuses to sit still for any of it. No story, no actors, no title cards. Just the joy of looking, cut at the speed of a heartbeat.</p>
            """),
        DemoReview(film: .nanook, author: .june, rating: 3.5, html: """
            <p>Half documentary, half staging, and the film doesn’t always tell you which half you’re watching. Knowing that changes it. It doesn’t erase the cold, though, or the patience of a man building an igloo while the camera waits with him.</p>
            """),
    ]

    // MARK: Spanish

    private static let spanish: [DemoReview] = [
        DemoReview(film: .nosferatu, author: .ines, rating: 4.5, liked: true, html: """
            <p>Murnau filma la peste como una llegada lenta: un barco sin nadie al timón, una sombra que sube la escalera antes que el cuerpo.</p>\
            <p>Cien años después, lo que más asusta sigue siendo la paciencia. Orlok nunca tiene prisa. <i>No le hace falta.</i></p>
            """),
        DemoReview(film: .caligari, author: .paco, rating: 4, rewatch: true, html: """
            <p>Todas las calles se tuercen como si quisieran huir de ti. Las sombras pintadas hacen la mitad del trabajo y la otra mitad es Conrad Veidt quieto, muy quieto.</p>\
            <blockquote><p>Tienes que convertirte en Caligari.</p></blockquote>\
            <p>El relato marco sigue cayendo como una trampilla. Sabía que venía y me pilló igual.</p>
            """),
        DemoReview(film: .lastLaugh, author: .ines, rating: 4, spoiler: true, html: """
            <p>El único intertítulo de la película se disculpa por el final que está a punto de darte. El guionista no soportó dejar al viejo portero en los lavabos, así que hereda una fortuna.</p>\
            <p>Es una trampa, Murnau lo sabe, y la broma es para nosotros por desearlo tanto.</p>
            """),
        DemoReview(film: .sunrise, author: .clara, rating: 5, liked: true, html: """
            <p>Vine por el famoso travelling por el pantano y me quedé por el tranvía. La secuencia en la ciudad es pura alegría: dos personas que casi se pierden reaprendiendo a hacer el tonto en público.</p>\
            <p>Murnau confía más en las caras que en los intertítulos. Hay tramos largos sin una sola línea de texto y nunca te pierdes, porque la cara de Janet Gaynor lo dice todo.</p>\
            <p>Lo que me queda es cómo la película se niega a ser una sola cosa. Es un thriller durante veinte minutos, una comedia romántica durante cuarenta, una tormenta en el lago durante diez, y no se le ve ninguna costura.</p>\
            <p>El final ilumina el pueblo con farolillos y entiendes que toda la película iba de la luz: la luna en el pantano, el neón de la ciudad, el sol saliendo sobre una cama.</p>\
            <p><b>Subtítulo:</b> <i>Una canción de dos humanos.</i> Se gana cada palabra.</p>
            """),
        DemoReview(film: .movieCamera, author: .clara, rating: 4.5, html: """
            <p>Una ciudad se despierta, trabaja, juega y se va a dormir, y la cámara se niega a quedarse quieta en ningún momento. Sin historia, sin actores, sin intertítulos. Solo el placer de mirar, montado al ritmo de un latido.</p>
            """),
        DemoReview(film: .nanook, author: .ines, rating: 3.5, html: """
            <p>Mitad documental, mitad puesta en escena, y la película no siempre te dice qué mitad estás viendo. Saberlo la cambia. Pero no borra el frío, ni la paciencia de un hombre levantando un iglú mientras la cámara espera con él.</p>
            """),
    ]

    // MARK: A Trip to the Moon

    private static let moonEnglish = DemoReview(film: .moon, author: .theo, rating: 4, liked: true, html: moonHTML("en"))
    private static let moonSpanish = DemoReview(film: .moon, author: .paco, rating: 4, liked: true, html: moonHTML("es"))

    private static func moonHTML(_ language: String) -> String {
        (moonTranslations[language] ?? []).map { "<p>\($0)</p>" }.joined()
    }

    /// The review in each interface language. English and Spanish are the
    /// originals; the rest is what the reel shows translated.
    private static let moonTranslations: [String: [String]] = [
        "en": [
            "Fourteen minutes, one rocket in the eye, and the whole idea of special effects arrives fully formed. Méliès was a magician first, and you can feel him enjoying every trick.",
            "The moon people vanish in a puff of smoke at the touch of an umbrella. I laughed out loud, more than a hundred years late.",
        ],
        "es": [
            "Catorce minutos, un cohete en el ojo y toda la idea de los efectos especiales llega ya completa. Méliès era mago antes que cineasta y se le nota disfrutando cada truco.",
            "Los selenitas se deshacen en humo con un golpe de paraguas. Me reí en voz alta, con más de cien años de retraso.",
        ],
        "de": [
            "Vierzehn Minuten, eine Rakete im Auge, und die ganze Idee der Spezialeffekte ist auf einmal fertig da. Méliès war zuerst Zauberkünstler, und man spürt, wie sehr er jeden Trick genießt.",
            "Die Mondbewohner lösen sich bei einer Berührung mit dem Regenschirm in Rauch auf. Ich habe laut gelacht, mit über hundert Jahren Verspätung.",
        ],
        "fr": [
            "Quatorze minutes, une fusée dans l’œil, et toute l’idée des effets spéciaux arrive déjà complète. Méliès était magicien avant tout, et on le sent savourer chaque tour.",
            "Les Sélénites partent en fumée d’un simple coup de parapluie. J’ai ri aux éclats, avec plus de cent ans de retard.",
        ],
        "it": [
            "Quattordici minuti, un razzo nell’occhio, e l’intera idea degli effetti speciali arriva già compiuta. Méliès era prima di tutto un illusionista, e si sente quanto si diverte con ogni trucco.",
            "I seleniti svaniscono in una nuvola di fumo al tocco di un ombrello. Ho riso ad alta voce, con più di cent’anni di ritardo.",
        ],
        "ja": [
            "14分間、目に刺さるロケットがひとつ。特殊効果という発想そのものが、最初から完成した姿で現れる。メリエスはまず奇術師だった。どのトリックも楽しんでいるのが伝わってくる。",
            "月の住人たちは、傘が触れただけで煙になって消えてしまう。百年以上遅れて、声を出して笑った。",
        ],
        "pt-BR": [
            "Quatorze minutos, um foguete no olho, e toda a ideia de efeitos especiais já chega pronta. Méliès era mágico antes de tudo, e dá para sentir o quanto ele se diverte com cada truque.",
            "Os selenitas viram fumaça com um toque de guarda-chuva. Ri alto, com mais de cem anos de atraso.",
        ],
        "zh-Hans": [
            "十四分钟，一枚火箭扎进月亮的眼睛，特效这个概念就此完整登场。梅里爱首先是一位魔术师，你能感受到他在享受每一个戏法。",
            "月球人被雨伞轻轻一碰，就化作一缕青烟。我笑出了声，晚了一百多年。",
        ],
    ]
}
#endif
