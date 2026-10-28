//
//  SettingsView.swift
//  VILLE
//
//  Look options (appearance, posters and backdrops), the session length,
//  and the attributions required by Letterboxd and TMDB.
//

import SwiftUI

/// `@AppStorage` keys, shared by every view that reads these settings.
enum SettingsKey {
    static let showPosters = "showPosters"
    static let showBackdrops = "showBackdrops"
    static let alternativePosters = "alternativePosters"
    static let sessionLength = "sessionLength"
    static let appearance = "appearance"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = true
    @AppStorage(SettingsKey.alternativePosters) private var alternativePosters = false
    @AppStorage(SettingsKey.sessionLength) private var sessionLength = SessionLength.standard
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Toggle("Posters", isOn: $showPosters)
                    Toggle("Alternative posters", isOn: $alternativePosters)
                        .disabled(!showPosters)
                    Toggle("Backdrops", isOn: $showBackdrops)
                } header: {
                    Text("Look")
                } footer: {
                    Text("Alternative posters picks a different one from TMDB each time, like other countries' releases. Tap any poster to flip to the next. Turn posters and backdrops off for text only.")
                }

                Section {
                    Picker("Reviews per session", selection: $sessionLength) {
                        ForEach(SessionLength.options, id: \.self) { length in
                            Text(verbatim: "\(length)").tag(length)
                        }
                    }
                } header: {
                    Text("Session")
                } footer: {
                    Text("The feed ends after this many reviews. Keep reading from the end card, or come back later for a new session.")
                }

                Section("About") {
                    Text("Reviews come from members' public Letterboxd RSS feeds and belong to their authors. VILLE is not affiliated with or endorsed by Letterboxd.")
                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                    // Official files from letterboxd.com/about/brand and
                    // themoviedb.org/about/logos-attribution. Letterboxd only
                    // allows its logo as a link to the platform.
                    Link(destination: URL(string: "https://letterboxd.com")!) {
                        AttributionLogo(image: .letterboxdLogo, label: "Letterboxd", height: 24)
                    }
                    Link(destination: URL(string: "https://www.themoviedb.org")!) {
                        AttributionLogo(image: .tmdbLogo, label: "The Movie Database (TMDB)", height: 14)
                    }
                }
                .font(.footnote)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}

/// A partner logo drawn from its official asset, never redrawn or recolored.
private struct AttributionLogo: View {
    let image: ImageResource
    let label: String
    let height: CGFloat

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .padding(.vertical, 4)
            .accessibilityLabel(label)
    }
}
