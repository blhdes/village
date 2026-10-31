//
//  BookmarksView.swift
//  VILLE
//
//  The reviews the reader bookmarked, newest bookmark first, opened from
//  People. Kept only on this iPhone, and never trimmed. A bookmark stays
//  after its member is removed. Tapping a row opens every bookmark on one
//  page that scrolls from review to review, starting at that one
//  (`BookmarksReader`). The bookmark under a review is the only way to
//  take it off.
//

import SwiftUI
import SwiftData

/// The bookmark a row opens.
private struct BookmarkRoute: Hashable {
    let reviewID: String
}

struct BookmarksView: View {
    @Query(
        filter: #Predicate<Review> { $0.bookmarkedAt != nil },
        sort: [SortDescriptor(\Review.bookmarkedAt, order: .reverse)]
    )
    private var bookmarks: [Review]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true

    var body: some View {
        List {
            ForEach(bookmarks) { review in
                // By value, not by view: taking a bookmark off on the page
                // drops its row here, and the page must stay open.
                NavigationLink(value: BookmarkRoute(reviewID: review.id)) {
                    row(review)
                }
            }
        }
        .overlay {
            if bookmarks.isEmpty {
                emptyState
            }
        }
        .navigationDestination(for: BookmarkRoute.self) { route in
            BookmarksReader(bookmarks: bookmarks, startID: route.reviewID)
        }
        .editorialTitle("Bookmarks")
    }

    /// The official poster, unless posters are off in Settings.
    private func posterURL(for review: Review) -> URL? {
        showPosters ? review.posterURL(pick: 0) : nil
    }

    private func row(_ review: Review) -> some View {
        HStack(spacing: 14) {
            if let url = posterURL(for: review) {
                PosterImage(url: url)
                    .frame(width: 40, height: 60)
                    .clipShape(.rect(cornerRadius: 2))
                    .overlay {
                        RoundedRectangle(cornerRadius: 2).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Text(review.filmTitle).fontWeight(.semibold))\(yearText(review))")
                    .font(.system(.body, design: .serif))
                    .lineLimit(2)
                // "Review by" in italic, the author upright, as in the header.
                Text("\(Text("Review by").italic().foregroundStyle(Color.primary.opacity(0.8))) \(Text(review.authorName))")
                    .font(.system(.subheadline, design: .serif))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    /// "  2026" in a lighter style after the title.
    private func yearText(_ review: Review) -> Text {
        guard let year = review.filmYear else { return Text(verbatim: "") }
        return Text(verbatim: "  \(year)")
            .foregroundStyle(Color.primary.opacity(0.65))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            EditorialHeadline(text: "No bookmarks yet")
                .multilineTextAlignment(.center)
            Text("Tap the bookmark under a review to keep it here, on this iPhone. It stays even if you stop following its author.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.primary.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

/// Every bookmark in full on one page, in the list's order: it opens at
/// the review that was tapped, with the newer bookmarks above and the
/// older ones below.
private struct BookmarksReader: View {
    /// The bookmarks as they were when the page opened. Taking one off here
    /// leaves the review in place with an empty bookmark (a second tap puts
    /// it back); only the list drops it. Without this copy the review being
    /// read would vanish from under the reader.
    @State private var reviews: [Review]
    @State private var position: ScrollPosition

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showRatings) private var showRatings = true

    init(bookmarks: [Review], startID: String) {
        _reviews = State(initialValue: bookmarks)
        _position = State(initialValue: ScrollPosition(id: startID, anchor: .top))
    }

    var body: some View {
        ScrollView {
            // Space alone separates one review's buttons from the next
            // poster: 32 here plus each review's own margins.
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(reviews) { review in
                    ReviewReader(
                        review: review,
                        // The official poster, as in the list.
                        posterURL: showPosters ? review.posterURL(pick: 0) : nil,
                        showRating: showRatings
                    )
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($position, anchor: .top)
        .scrollIndicators(.hidden)
        .background(Color.reelBackground)
    }
}
