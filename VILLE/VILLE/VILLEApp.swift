//
//  VILLEApp.swift
//  VILLE
//
//  App entry point. Sets up the SwiftData model container and forces a
//  dark, cinematic appearance across the entire app.
//

import SwiftUI
import SwiftData

@main
struct VILLEApp: App {
    /// Single SwiftData container for the whole app — passed down via
    /// `.modelContainer(_:)` so every view can use `@Query` and `@Environment(\.modelContext)`.
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: Review.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            FeedView()
                // Dark mode only — part of VILLE's cinematic identity.
                .preferredColorScheme(.dark)
                // Smooth system-wide tint; cards/glass will override locally.
                .tint(.white)
        }
        .modelContainer(container)
    }
}
