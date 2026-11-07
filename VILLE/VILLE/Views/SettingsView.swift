//
//  SettingsView.swift
//  VILLE
//
//  Settings, from how a reel looks to what VILLE is: the reel on screen in
//  miniature (`LookPreview`), Look (the appearance as three small pages,
//  then posters, backdrops, stars and likes), Reading (the session length,
//  whether reviews come back, whether very short ones are hidden),
//  Language, Storage (`StorageSection`) and About (`AboutSection`). Icons
//  stay monochrome, in the text color, so the brand's colors keep their
//  meaning.
//

import SwiftUI

/// `@AppStorage` keys, shared by every view that reads these settings.
enum SettingsKey {
    static let showPosters = "showPosters"
    /// Off by default: a reel opens on plain type. Every `@AppStorage`
    /// that reads it must default to false too.
    static let showBackdrops = "showBackdrops"
    static let alternativePosters = "alternativePosters"
    static let showRatings = "showRatings"
    static let sessionLength = "sessionLength"
    static let hideShortReviews = "hideShortReviews"
    static let showEachReviewOnce = "showEachReviewOnce"
    static let appearance = "appearance"
}

struct SettingsView: View {
    /// The reel on screen (or a stand-in), drawn at the top with the
    /// current look. Nil until the library has a review.
    var preview: LookPreview.Sample?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = false
    @AppStorage(SettingsKey.alternativePosters) private var alternativePosters = false
    @AppStorage(SettingsKey.showRatings) private var showRatings = true
    @AppStorage(SettingsKey.sessionLength) private var sessionLength = SessionLength.standard
    @AppStorage(SettingsKey.hideShortReviews) private var hideShortReviews = false
    @AppStorage(SettingsKey.showEachReviewOnce) private var showEachReviewOnce = false
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    private var look: ReelLook {
        ReelLook(
            showPoster: showPosters,
            showBackdrop: showBackdrops,
            alternativePosters: alternativePosters,
            showRating: showRatings
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let preview {
                    Section {
                        LookPreview(sample: preview, look: look)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                lookSection
                readingSection
                languageSection
                StorageSection()
                AboutSection()
            }
            .editorialTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        // The app's root sets the appearance for the window, but this sheet
        // is a presentation of its own: a color scheme preference only
        // reaches the presentation whose views set it, so the root's choice
        // arrived here only when the sheet opened. Set here too, a new pick
        // redraws this screen, preview included, at once.
        .preferredColorScheme(appearance.colorScheme)
    }
}

// MARK: - Sections

private extension SettingsView {
    var lookSection: some View {
        Section {
            AppearancePicker(selection: $appearance)

            Toggle(isOn: $showPosters) {
                Label("Posters", systemImage: "rectangle.portrait")
            }
            // Not the app's tint (the text color): in dark mode a white
            // switch hid its white knob. Black in light, gray in dark.
            .tint(Color.toggleOn)
            Toggle(isOn: $alternativePosters) {
                Label("Alternative posters", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
            }
            .tint(Color.toggleOn)
            .disabled(!showPosters)
            Toggle(isOn: $showBackdrops) {
                Label("Backdrops", systemImage: "film")
            }
            .tint(Color.toggleOn)
            Toggle(isOn: $showRatings) {
                Label("Stars and likes", systemImage: "star.leadinghalf.filled")
            }
            .tint(Color.toggleOn)
        } header: {
            Text("Look")
        } footer: {
            Text("Alternative posters picks a different one from TMDB each time, like other countries’ releases. Tap any poster to flip to the next.")
        }
    }

    /// Sections under one header, so each control keeps its own note.
    @ViewBuilder
    var readingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reviews per session", systemImage: "rectangle.stack")
                Picker("Reviews per session", selection: $sessionLength) {
                    ForEach(SessionLength.options, id: \.self) { length in
                        Text(verbatim: "\(length)").tag(length)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.vertical, 4)
        } header: {
            Text("Reading")
        } footer: {
            Text("The feed ends after this many reviews. Keep reading from the end card, or come back later for a new session.")
        }

        Section {
            Toggle(isOn: $showEachReviewOnce) {
                Label("Show each review once", systemImage: "text.badge.checkmark")
            }
            .tint(Color.toggleOn)
        } footer: {
            Text("Reviews you’ve seen don’t come back. When it’s off, sessions bring back the ones you saw longest ago once there’s nothing new.")
        }

        Section {
            Toggle(isOn: $hideShortReviews) {
                Label("Hide very short reviews", systemImage: "text.badge.minus")
            }
            .tint(Color.toggleOn)
        } footer: {
            Text("Reviews under ^[\(ReviewLength.shortLimit) words](inflect: true), like one-liners, stay out of the feed. Bookmarks keep them.")
        }
    }

    var languageSection: some View {
        Section {
            Button(action: openLanguageSettings) {
                HStack {
                    Label {
                        Text(verbatim: Self.currentLanguageName)
                    } icon: {
                        Image(systemName: "globe")
                    }
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .imageScale(.small)
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            }
            .accessibilityHint("Opens VILLE in iOS Settings")
        } header: {
            Text("Language")
        } footer: {
            Text("VILLE follows your iPhone. To read it in another language, tap and choose one under Language. Translations follow it too.")
        }
    }
}

// MARK: - Language

private extension SettingsView {
    /// The language VILLE shows right now, named in itself ("Español",
    /// "Deutsch", "日本語"), as iOS lists languages.
    static var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        let name = Locale(identifier: code).localizedString(forIdentifier: code) ?? code
        return name.prefix(1).capitalized(with: Locale(identifier: code)) + name.dropFirst()
    }

    /// iOS picks the language per app on VILLE's page in its own Settings
    /// (it appears once the app ships in two or more languages); VILLE
    /// starts again in it. Apple's way: an in-app picker could only apply
    /// after a manual restart, and system sheets wouldn't follow it.
    func openLanguageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            print("SettingsView: could not build the iOS Settings URL")
            return
        }
        openURL(url)
    }
}
