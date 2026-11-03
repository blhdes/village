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
    @State private var translator = ReviewTranslator()
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    init() {
        // Keeps TMDB art around between launches and offline, up to a limit.
        LocalStorage.configureDownloadCache()

        do {
            // A new store name: the reels model doesn't match the old scaffold's
            // data, so we start clean instead of migrating it.
            let configuration = ModelConfiguration("VILLEReels")
            container = try ModelContainer(for: Review.self, FollowedUser.self, configurations: configuration)
        } catch {
            fatalError("VILLEApp: could not create the SwiftData container — \(error)")
        }
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
        }
        .modelContainer(container)
    }
}
