//
//  SettingsView.swift
//  VILLE
//
//  Look options (posters and backdrops on/off) and the attributions required
//  by Letterboxd and TMDB.
//

import SwiftUI

/// `@AppStorage` keys, shared by every view that reads these settings.
enum SettingsKey {
    static let showPosters = "showPosters"
    static let showBackdrops = "showBackdrops"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Posters", isOn: $showPosters)
                    Toggle("Backdrops", isOn: $showBackdrops)
                } header: {
                    Text("Look")
                } footer: {
                    Text("Turn both off for text only.")
                }

                Section("About") {
                    Text("Reviews come from members' public Letterboxd RSS feeds and belong to their authors. VILLE is not affiliated with or endorsed by Letterboxd.")
                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                    Link("Letterboxd", destination: URL(string: "https://letterboxd.com")!)
                    Link("The Movie Database (TMDB)", destination: URL(string: "https://www.themoviedb.org")!)
                }
                .font(.footnote)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
