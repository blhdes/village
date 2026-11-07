//
//  AboutSection.swift
//  VILLE
//
//  Settings → About: the privacy policy and a way to get help or write to
//  us (Apple asks for both inside the app: guidelines 5.1.1 and 1.5), a
//  link to rate VILLE on the App Store (after which the Fin cards stop
//  asking: `RatingRequest`), the credits Letterboxd and TMDB require, and
//  the version at the very end.
//

import SwiftUI

struct AboutSection: View {
    @Environment(\.openURL) private var openURL
    @AppStorage(RatingRequest.askCountKey) private var ratingAsks = 0

    private static let privacyURL = URL(string: "https://blhdes.github.io/village/privacy.html")!
    /// The support page, which has the contact email.
    private static let supportURL = URL(string: "https://blhdes.github.io/village/")!
    /// The App Store's "Write a Review" page for VILLE.
    private static let reviewURL = URL(string: "https://apps.apple.com/app/id6829207754?action=write-review")!

    var body: some View {
        Section("About") {
            // The pages open in Safari inside the app, like links in
            // reviews; the review page opens the App Store itself.
            linkRow("Privacy policy", systemImage: "hand.raised") {
                openURL(Self.privacyURL, prefersInApp: true)
            }
            linkRow("Help and contact", systemImage: "questionmark.circle") {
                openURL(Self.supportURL, prefersInApp: true)
            }
            linkRow("Rate VILLE", systemImage: "star.bubble") {
                // They went to rate on their own: the Fin cards stop asking.
                ratingAsks = RatingRequest.maxAsks
                openURL(Self.reviewURL)
            }
        }

        Section {
            Text("Reviews come from members’ public Letterboxd RSS feeds and belong to their authors. VILLE is not affiliated with or endorsed by Letterboxd.")
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
        } footer: {
            Text(verbatim: Self.versionLine)
                .datelineStyle()
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
        .font(.footnote)
    }

    /// A row that leaves Settings: icon, title, and the arrow that says so.
    private func linkRow(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .imageScale(.small)
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
        }
    }

    /// "VILLE 1.0 (1)": the version and build, from the app's Info.plist.
    private static var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "VILLE \(version) (\(build))"
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
