//
//  StoreDemo.swift
//  VILLE
//
//  Demo mode for the App Store screenshots (store/SCREENSHOTS.md). Debug
//  builds only: Release leaves the whole StoreDemo folder out
//  (`EXCLUDED_SOURCE_FILE_NAMES`), and every hook in the app sits behind
//  `#if DEBUG`.
//
//  The `VILLEStoreShots` UI test launches VILLE with
//  `-StoreScreenshots <shot>`. VILLE then reads a fictional library kept in
//  memory (`StoreDemoContent`), never the reader's own; fetches no feeds;
//  keeps Settings in a store of its own, cleared at each launch; shows the
//  reels in a fixed order with fixed art (public-domain film frames, as
//  backdrops and as posters); and
//  hides the status bar. Same screens on every run.
//

#if DEBUG
import SwiftUI
import SwiftData

/// One store screenshot: the reel it opens on and how Settings are set.
/// The raw values are the names the UI test passes and the captures get.
enum StoreShot: String, CaseIterable {
    case reel = "1-reel"
    case words = "2-words"
    case spoiler = "3-spoiler"
    case fin = "4-fin"
    case translation = "5-translation"
    case people = "6-people"
    case settings = "7-settings"

    var appearance: Appearance {
        switch self {
        case .reel, .spoiler, .fin, .settings: .dark
        case .words, .translation, .people: .light
        }
    }

    /// The film of the first reel.
    var firstFilm: DemoFilm {
        switch self {
        case .reel, .fin: .nosferatu
        case .words: .caligari
        case .spoiler: .lastLaugh
        case .translation: .moon
        case .people, .settings: .sunrise
        }
    }

    /// "The words first": the shot without stars.
    var showsRatings: Bool { self != .words }

    /// Backdrops on half the reel shots, the dark ones: VILLE reads as
    /// well without them (they're off by default), and the light shots
    /// show that. Off in Settings: "Text only, if you like".
    var showsBackdrops: Bool {
        switch self {
        case .reel, .spoiler: true
        case .words, .fin, .translation, .people, .settings: false
        }
    }

    /// "Text only, if you like": Settings with Posters off too.
    var showsPosters: Bool { self != .settings }
}

struct StoreDemo {
    let shot: StoreShot
    /// VILLE's interface language for this run: "en", "es", "de"…
    let language: String
    /// Settings for this run, apart from the reader's own.
    let settings: UserDefaults

    /// Set when VILLE was launched for a store screenshot; nil otherwise.
    static let current: StoreDemo? = {
        guard let name = UserDefaults.standard.string(forKey: "StoreScreenshots") else { return nil }
        guard let shot = StoreShot(rawValue: name) else {
            print("StoreDemo: unknown shot \(name), launching normally")
            return nil
        }
        guard let settings = UserDefaults(suiteName: settingsSuite) else {
            print("StoreDemo: could not open the settings store \(settingsSuite), launching normally")
            return nil
        }
        settings.removePersistentDomain(forName: settingsSuite)
        write(shot, to: settings)
        return StoreDemo(shot: shot, language: Bundle.main.preferredLocalizations.first ?? "en", settings: settings)
    }()

    private static let settingsSuite = "agu.VILLE.StoreDemo"

    /// Posters and backdrops are both frames from the films themselves
    /// (`DemoFilm.hasPoster`, `hasFrame`), never real posters.
    private static func write(_ shot: StoreShot, to settings: UserDefaults) {
        settings.set(shot.showsPosters, forKey: SettingsKey.showPosters)
        settings.set(false, forKey: SettingsKey.alternativePosters)
        settings.set(shot.showsBackdrops, forKey: SettingsKey.showBackdrops)
        settings.set(shot.showsRatings, forKey: SettingsKey.showRatings)
        settings.set(SessionLength.standard, forKey: SettingsKey.sessionLength)
        settings.set(false, forKey: SettingsKey.hideShortReviews)
        settings.set(false, forKey: SettingsKey.showEachReviewOnce)
        settings.set(shot.appearance.rawValue, forKey: SettingsKey.appearance)
    }

    private var content: StoreDemoContent { StoreDemoContent(language: language) }

    // MARK: Hooks

    /// The demo library, in memory only.
    func makeContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Review.self, FollowedUser.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            content.insert(into: container.mainContext, for: shot)
            try container.mainContext.save()
            return container
        } catch {
            fatalError("StoreDemo: could not build the demo library — \(error)")
        }
    }

    /// The reels in a fixed order, the shot's film first, instead of
    /// `ReelSampler`'s chance.
    func arrange(_ candidates: [ReelCandidate], count: Int) -> [ReelCandidate] {
        let order = [shot.firstFilm] + DemoFilm.allCases.filter { $0 != shot.firstFilm }
        let ids = order.map(StoreDemoContent.reviewID)
        let rank = { (candidate: ReelCandidate) in ids.firstIndex(of: candidate.id) ?? ids.count }
        return Array(candidates.sorted { rank($0) < rank($1) }.prefix(count))
    }

    /// A Trip to the Moon, written in another language, opens translated
    /// into the interface's: the translation is ours, written as
    /// Translation would give it, since a test run can't wait for Apple's
    /// language downloads.
    func showTranslation(in translator: ReviewTranslator) {
        let moon = content.moon
        translator.preload(moon.translation, for: StoreDemoContent.reviewID(.moon), html: moon.html)
    }

    /// Suggestions with fictional names, instead of real members.
    var suggestions: [SuggestedMember] { content.suggestions }

    /// The bundled film frame for a demo art path ("/storedemo/nosferatu"),
    /// or nil for any other path.
    nonisolated static func frameURL(for path: String) -> URL? {
        let prefix = "/storedemo/"
        guard path.hasPrefix(prefix) else { return nil }
        let name = "storedemo-" + path.dropFirst(prefix.count)
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else {
            print("StoreDemo: no frame named \(name).jpg in the bundle")
            return nil
        }
        return url
    }
}

extension View {
    /// Store screenshots: the shot's own Settings, no status bar. Does
    /// nothing on a normal launch.
    @ViewBuilder
    func storeDemo() -> some View {
        if let demo = StoreDemo.current {
            defaultAppStorage(demo.settings)
                .statusBarHidden()
        } else {
            self
        }
    }
}
#endif
