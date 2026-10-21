//
//  VILLEApp.swift
//  VILLE
//
//  App entry point. Sets up SwiftData, a larger image cache for posters and
//  backdrops, and the shared `FeedViewModel`.
//

import SwiftUI
import SwiftData

@main
struct VILLEApp: App {
    private let container: ModelContainer
    @State private var viewModel: FeedViewModel

    init() {
        // AsyncImage goes through URLSession.shared — a bigger cache keeps
        // TMDB art around between launches and offline.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)

        do {
            // A new store name: the reels model doesn't match the old scaffold's
            // data, so we start clean instead of migrating it.
            let configuration = ModelConfiguration("VILLEReels")
            container = try ModelContainer(for: Review.self, FollowedUser.self, configurations: configuration)
        } catch {
            fatalError("VILLEApp: could not create the SwiftData container — \(error)")
        }
        _viewModel = State(initialValue: FeedViewModel(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ReelFeedView()
                .environment(viewModel)
                // Dark mode only — part of VILLE's cinematic identity.
                .preferredColorScheme(.dark)
                .tint(.white)
        }
        .modelContainer(container)
    }
}
