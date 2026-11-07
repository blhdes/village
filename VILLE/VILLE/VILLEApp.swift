//
//  VILLEApp.swift
//  VILLE
//
//  App entry point. Sets up SwiftData, the download cache for posters and
//  backdrops (`LocalStorage`), the shared `FeedViewModel` (the library),
//  `ReelSession` (what's on screen) and `ReviewTranslator` (reviews shown
//  translated). Trims the library once per launch.
//

import SwiftUI
import SwiftData

@main
struct VILLEApp: App {
    private let container: ModelContainer
    @State private var viewModel: FeedViewModel
    @State private var session: ReelSession
    @State private var translator: ReviewTranslator
    @AppStorage private var appearance: Appearance

    init() {
        // Keeps TMDB art around between launches and offline, up to a limit.
        LocalStorage.configureDownloadCache()

        #if DEBUG
        // Store screenshots keep their Settings apart (`StoreDemo`).
        let settings = StoreDemo.current?.settings
        #else
        let settings: UserDefaults? = nil
        #endif
        // Nil: the app's own settings.
        _appearance = AppStorage(wrappedValue: .system, SettingsKey.appearance, store: settings)

        container = Self.makeContainer()
        let translator = ReviewTranslator()
        #if DEBUG
        StoreDemo.current?.showTranslation(in: translator)
        #endif
        _translator = State(initialValue: translator)

        let viewModel = FeedViewModel(context: container.mainContext)
        // Here, before the first session is picked, so no reel on screen
        // can disappear.
        viewModel.trimLibrary()
        _viewModel = State(initialValue: viewModel)
        _session = State(initialValue: ReelSession(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ReelFeedView()
                .environment(viewModel)
                .environment(session)
                .environment(translator)
                // Which languages this iPhone can translate, so reviews in
                // other languages can offer "Translate".
                .task { await translator.loadSupportedLanguages() }
                // System, Light or Dark, picked in Settings.
                .preferredColorScheme(appearance.colorScheme)
                .tint(Color.primary)
                #if DEBUG
                .storeDemo()
                #endif
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        #if DEBUG
        // Store screenshots: a fictional library in memory, never the reader's.
        if let demo = StoreDemo.current { return demo.makeContainer() }
        #endif
        do {
            // A new store name: the reels model doesn't match the old scaffold's
            // data, so we start clean instead of migrating it.
            let configuration = ModelConfiguration("VILLEReels")
            return try ModelContainer(for: Review.self, FollowedUser.self, configurations: configuration)
        } catch {
            fatalError("VILLEApp: could not create the SwiftData container — \(error)")
        }
    }
}
