//
//  ReviewByline.swift
//  VILLE
//
//  "Review by" in italic, the author upright, both serif. On a reel it
//  opens the author's menu: their profile and Report on Letterboxd, where
//  the review lives, plus Unfollow in the feed (App Store guideline 1.2:
//  report and block, from the content itself). A member's feed opened
//  from People leaves Unfollow out. The reader, Bookmarks and the Settings
//  preview keep the byline plain.
//

import SwiftUI

/// What tapping "Review by …" offers.
enum BylineMenu {
    /// Nothing: a plain byline.
    case none
    /// The author's profile and Report on Letterboxd.
    case report
    /// Those and Unfollow, which calls this (the reel asks first).
    case reportAndUnfollow(() -> Void)
}

struct ReviewByline: View {
    let review: Review
    var menu: BylineMenu = .none

    @Environment(\.openURL) private var openURL

    var body: some View {
        switch menu {
        case .none:
            text
        case .report:
            authorMenu(onUnfollow: nil)
        case .reportAndUnfollow(let onUnfollow):
            authorMenu(onUnfollow: onUnfollow)
        }
    }

    private var text: some View {
        Text("\(Text("Review by").italic().foregroundStyle(Color.primary.opacity(0.8))) \(Text(review.authorName).fontWeight(.semibold))")
            .font(.system(.subheadline, design: .serif))
    }

    private func authorMenu(onUnfollow: (() -> Void)?) -> some View {
        let hint: LocalizedStringKey = onUnfollow == nil ? "Profile or report" : "Profile, report or unfollow"
        return Menu {
            Button("Profile on Letterboxd", systemImage: "person.crop.circle") {
                open(review.authorProfileURL)
            }
            Button("Report on Letterboxd", systemImage: "flag") {
                open(review.url)
            }
            if let onUnfollow {
                Button("Unfollow", systemImage: "person.badge.minus", role: .destructive, action: onUnfollow)
            }
        } label: {
            // A taller hit area than the line itself, without moving it.
            text
                .padding(.vertical, 8)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .padding(.vertical, -8)
        .accessibilityHint(hint)
    }

    /// Letterboxd's own app opens it when installed, signed in, as "View on
    /// Letterboxd" does: reporting needs the reader's account.
    private func open(_ url: URL?) {
        guard let url else {
            print("ReviewByline: no Letterboxd link for review \(review.id)")
            return
        }
        openURL(url)
    }
}
