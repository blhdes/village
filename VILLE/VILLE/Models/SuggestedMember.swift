//
//  SuggestedMember.swift
//  VILLE
//
//  A hand-picked list of Letterboxd members who post written reviews often
//  (critics, writers, filmmakers, creators), offered on the People screen
//  until the user follows a few people. Usernames and display names only:
//  nothing is fetched until the user adds someone, and no reviews are
//  bundled (Letterboxd ToS 6.8 — keep it small and hand-picked).
//
//  Checked 2026-10-28 against each member's public RSS feed: a written
//  review in the last 30 days, at least two that month and more in the two
//  months before, and real text, not one-liners. Re-check before each
//  release and drop anyone who has gone quiet.
//

import Foundation

struct SuggestedMember: Identifiable, Hashable {
    /// Lowercase Letterboxd handle — the part after letterboxd.com/.
    let username: String
    /// Name shown on Letterboxd when the list was checked.
    let displayName: String
    /// Language the member mostly writes in (ISO 639-1).
    let language: String

    init(_ username: String, _ displayName: String, language: String = "en") {
        self.username = username
        self.displayName = displayName
        self.language = language
    }

    var id: String { username }

    var profileURL: URL? { URL(string: "https://letterboxd.com/\(username)/") }
}

extension SuggestedMember {
    /// Suggestions stop once the user follows this many members.
    static let enoughMembers = 10

    /// Up to `count` random suggestions, leaving out `taken` usernames.
    static func pick(_ count: Int, excluding taken: Set<String>) -> [SuggestedMember] {
        #if DEBUG
        // Store screenshots: fictional names, never real members.
        if let demo = StoreDemo.current {
            return Array(demo.suggestions.filter { !taken.contains($0.username) }.prefix(count))
        }
        #endif
        return Array(readable.filter { !taken.contains($0.username) }.shuffled().prefix(count))
    }

    /// English for everyone; other languages only for readers whose iPhone
    /// lists them, so nobody is offered reviews they can't read.
    private static var readable: [SuggestedMember] {
        let languages = Set(Locale.preferredLanguages.compactMap {
            Locale(identifier: $0).language.languageCode?.identifier
        })
        return all.filter { $0.language == "en" || languages.contains($0.language) }
    }

    static let all: [SuggestedMember] = [
        // English
        SuggestedMember("812filmreviews", "Robert Daniels"),
        SuggestedMember("aarkush", "Allan Arkush"),
        SuggestedMember("alor", "alor"),
        SuggestedMember("amandathejedi", "Amanda the Jedi"),
        SuggestedMember("andredenervaux", "Andre de Nervaux"),
        SuggestedMember("benjybox", "Ben Challoner"),
        SuggestedMember("bethanyinfilm", "Bethany"),
        SuggestedMember("brat", "mia lee vicino"),
        SuggestedMember("brendanmleonard", "BrendanMLeonard"),
        SuggestedMember("brianformo", "Brian Formo"),
        SuggestedMember("cantinaband", "Wes"),
        SuggestedMember("carrieandtracy", "carrieandtracy"),
        SuggestedMember("cfyvie", "Chris Fyvie"),
        SuggestedMember("cinemavoid", "CinemaVoid 🏴‍☠️"),
        SuggestedMember("clevack", "Chandler Levack"),
        SuggestedMember("clintworthing", "Clint Worthington"),
        SuggestedMember("coreyatad", "Corey Atad"),
        SuggestedMember("cynicalfilm", "Philip Bagnall"),
        SuggestedMember("davidehrlich", "davidehrlich"),
        SuggestedMember("deathproof", "Lucy"),
        SuggestedMember("deepfocusreview", "Brian Eggert"),
        SuggestedMember("demiadejuyigbe", "demi adejuyigbe"),
        SuggestedMember("dgmiller", "Duane Miller"),
        SuggestedMember("drewmcweeny", "DrewMcWeeny"),
        SuggestedMember("edouglasww", "Edward Douglas"),
        SuggestedMember("electricdreams", "Fred Barrett"),
        SuggestedMember("ellakemp", "Ella Kemp"),
        SuggestedMember("enniomorricone", "Erik 🎼"),
        SuggestedMember("fatalkoala", "Kurtis Belanger"),
        SuggestedMember("firstshowing", "Alex Billington"),
        SuggestedMember("framesofnick", "Framesofnick"),
        SuggestedMember("gemko", "Mike D'Angelo"),
        SuggestedMember("hastapura", "haunted house"),
        SuggestedMember("heythisisjames", "Movie Good or Movie Bad?"),
        SuggestedMember("ianhecox", "Ian Hecox"),
        SuggestedMember("jack", "Jack Moulton"),
        SuggestedMember("jacobbeanwatson", "Jacob Bean-Watson"),
        SuggestedMember("jacobknight", "Jacob Knight"),
        SuggestedMember("jakepcole", "Jake Cole"),
        SuggestedMember("jaredgilman", "Jared Gilman"),
        SuggestedMember("jaredmobarak", "Jared Mobarak"),
        SuggestedMember("jbouie", "Jamelle Bouie"),
        SuggestedMember("jeffrauseo", "Jeff Rauseo"),
        SuggestedMember("jlalibs", "Justin LaLiberty"),
        SuggestedMember("joelhaver", "Joel Haver"),
        SuggestedMember("jonathanfujii", "jonathan fujii"),
        SuggestedMember("jumblejim", "Jim Beaver"),
        SuggestedMember("katiewalshstx", "Katie Walsh"),
        SuggestedMember("kurstboy", "Karsten"),
        SuggestedMember("loganmiller8", "Logan Miller"),
        SuggestedMember("maiapog", "maiapog"),
        SuggestedMember("mattcipolla", "Matt Cipolla"),
        SuggestedMember("michaelmohan", "michaelmohan"),
        SuggestedMember("michelliesfilm", "michellie"),
        SuggestedMember("moviejawn", "MovieJawn"),
        SuggestedMember("moviesrtherapy", "Kit Lazer"),
        SuggestedMember("movieswithmark", "movieswithmark"),
        SuggestedMember("mubi", "MUBI"),
        SuggestedMember("nextbestpicture", "Matt Neglia"),
        SuggestedMember("oldfilmsflicker", "Marya E. Gates"),
        SuggestedMember("patrick_ryan", "Patrick Ryan"),
        SuggestedMember("patrickhwillems", "Patrick Willems"),
        SuggestedMember("philbertdy", "Philbert Dy"),
        SuggestedMember("rayshh", "RayShh"),
        SuggestedMember("rogerebert", "RogerEbert.com"),
        SuggestedMember("ruffreader", "Joshua Booker"),
        SuggestedMember("rupertpupkin", "Brian Saur"),
        SuggestedMember("scenethispod", "MICHAEL ORNELAS"),
        SuggestedMember("schaffrillas", "James (Schaffrillas)"),
        SuggestedMember("screened_scored", "Screened & Scored"),
        SuggestedMember("screenslate", "Screen Slate"),
        SuggestedMember("shadowtodd", "shadowtodd"),
        SuggestedMember("shookone", "shookone"),
        SuggestedMember("sightsoundmag", "Sight and Sound"),
        SuggestedMember("superpulse", "Matt Singer"),
        SuggestedMember("suspirliam", "˗ˏˋ suspirliam ˊˎ˗"),
        SuggestedMember("swag_movies", "swag"),
        SuggestedMember("theamynicholson", "Amy Nicholson"),
        SuggestedMember("thejoelynch", "Joe Lynch"),
        SuggestedMember("thejoshl", "Josh Lewis"),
        SuggestedMember("thisisalexei", "Alexei Toliopoulos"),
        SuggestedMember("thomasflight", "Thomas Flight"),
        SuggestedMember("tomreviewsfilmz", "TomReviewsFilmz"),
        SuggestedMember("veradrew22", "Vera Drew"),
        SuggestedMember("worldforgot", "WorldForgot"),
        SuggestedMember("zacharyruane", "Zachary Ruane"),
        SuggestedMember("zkraus", "Pretentious Film Critic"),
        SuggestedMember("zoerosebryant", "zoë rose bryant"),

        // Spanish
        SuggestedMember("alcorona", "AlCorona", language: "es"),
        SuggestedMember("chechitobcn", "ChechitoBCN", language: "es"),
        SuggestedMember("cinefagos", "oswaldo osorio", language: "es"),
        SuggestedMember("cinoscararities", "CinoscaRarities", language: "es"),
        SuggestedMember("critic17_", "Critic", language: "es"),
        SuggestedMember("diegobatlle", "DIEGO BATLLE", language: "es"),
        SuggestedMember("diezmartinez", "Ernesto Diezmartinez", language: "es"),
        SuggestedMember("eamcinema", "El antepenúltimo mohicano", language: "es"),
        SuggestedMember("francotoskarc", "Rincón Cinéfilo", language: "es"),
        SuggestedMember("freirejuanma", "Juan Manuel Freire", language: "es"),
        SuggestedMember("juanrico", "cineMAme", language: "es"),

        // French
        SuggestedMember("lamanieducinema", "Mélanie Toubeau", language: "fr"),
    ]
}
