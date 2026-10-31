//
//  BookmarksView.swift
//  VILLE
//
//  The reviews the reader bookmarked, newest bookmark first, opened from
//  People. Kept only on this iPhone, and never trimmed. A bookmark stays
//  after its member is removed. Tapping a row opens the full reader;
//  swiping takes the bookmark off.
//

import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Review> { $0.bookmarkedAt != nil },
        sort: [SortDescriptor(\Review.bookmarkedAt, order: .reverse)]
    )
    private var bookmarks: [Review]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showRatings) private var showRatings = true

    var body: some View {
        List {
            ForEach(bookmarks) { review in
                // By id, not by view: taking the bookmark off inside the
                // reader drops this row, and the reader must stay open.
                NavigationLink(value: review.persistentModelID) {
                    row(review)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.toggleBookmark(review)
                    } label: {
                        Label("Remove bookmark", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .overlay {
            if bookmarks.isEmpty {
                emptyState
            }
        }
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let review = modelContext.model(for: id) as? Review {
                ReviewReader(review: review, posterURL: posterURL(for: review), showRating: showRatings)
            }
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
