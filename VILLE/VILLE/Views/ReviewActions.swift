//
//  ReviewActions.swift
//  VILLE
//
//  The buttons under a review: Share, "View on Letterboxd" and the
//  bookmark. Used by both the reel and the full reader.
//

import SwiftUI

/// Share (as a link to the original — never the text itself, per Letterboxd's
/// ToS on exporting others' content), open the review on Letterboxd, and
/// bookmark it on this iPhone (People → Bookmarks).
struct ReviewActions: View {
    let review: Review
    let url: URL
    /// The poster on screen (nil with posters off): a new bookmark keeps it.
    let posterPick: Int?

    @Environment(FeedViewModel.self) private var viewModel

    @State private var bookmarkTaps = 0

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            // With large text sizes, Share drops its title first, then the
            // buttons take two lines, so "View on Letterboxd" (the credit)
            // always keeps its words.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    shareButton(showsTitle: true)
                    letterboxdLink
                    Spacer(minLength: 0)
                    bookmarkButton
                }
                HStack(spacing: 10) {
                    shareButton(showsTitle: false)
                    letterboxdLink
                    Spacer(minLength: 0)
                    bookmarkButton
                }
                VStack(alignment: .leading, spacing: 10) {
                    letterboxdLink
                    HStack(spacing: 10) {
                        shareButton(showsTitle: false)
                        bookmarkButton
                    }
                }
            }
            .font(.system(.subheadline, design: .serif, weight: .medium))
            .buttonStyle(.glass)
        }
        .sensoryFeedback(.selection, trigger: bookmarkTaps)
    }

    @ViewBuilder
    private func shareButton(showsTitle: Bool) -> some View {
        let link = ShareLink(
            item: url,
            subject: Text(review.filmTitle),
            message: Text("\(review.filmTitle) · review by \(review.authorName)")
        ) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        if showsTitle {
            link
        } else {
            link.labelStyle(.iconOnly)
        }
    }

    /// Official dots badge from Letterboxd's Brand page — allowed here
    /// because the button links to letterboxd.com.
    private var letterboxdLink: some View {
        Link(destination: url) {
            Label {
                Text("View on Letterboxd")
            } icon: {
                Image(.letterboxdDots)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
    }

    /// Keeps the review in People → Bookmarks, or takes it out. The symbol
    /// fills in place; the label says what a tap will do.
    private var bookmarkButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.toggleBookmark(review, posterPick: posterPick)
            }
            bookmarkTaps += 1
        } label: {
            Label(bookmarkTitle, systemImage: review.isBookmarked ? "bookmark.fill" : "bookmark")
                .labelStyle(.iconOnly)
                .contentTransition(.symbolEffect(.replace))
        }
    }

    private var bookmarkTitle: LocalizedStringKey {
        review.isBookmarked ? "Remove bookmark" : "Bookmark"
    }
}
