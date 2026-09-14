//
//  FeedView.swift
//  VILLE
//
//  Main screen. Shows a vertically-scrolling feed of `ReviewCard`s backed
//  by SwiftData's `@Query`. Pull-to-refresh triggers a background RSS
//  refresh through `FeedViewModel`.
//
//  Already wrapped in a `TabView` so future tabs (Saved, Profile) can
//  slot in without restructuring.
//

import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext

    /// SwiftData auto-updates this whenever the DB changes — so after the
    /// VM inserts fresh reviews, the feed re-renders for free.
    @Query(sort: \Review.publishedAt, order: .reverse)
    private var reviews: [Review]

    /// View model lives for the lifetime of this view.
    @State private var viewModel = FeedViewModel()

    /// Tab selection — scaffolded for future tabs. Only Feed exists for now.
    @State private var selectedTab: Tab = .feed

    enum Tab: Hashable { case feed }

    var body: some View {
        TabView(selection: $selectedTab) {
            feedTab
                .tag(Tab.feed)
                .tabItem {
                    Label("Feed", systemImage: "film.stack")
                }
        }
        .tint(.white)
    }

    // MARK: Feed tab

    private var feedTab: some View {
        NavigationStack {
            ZStack {
                // Deep cinematic background sits beneath the glass cards.
                cinematicBackground.ignoresSafeArea()

                if reviews.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }
            .navigationTitle("VILLE")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable { await viewModel.refresh() }
            .task {
                // Bind once — .task fires after the environment is ready.
                viewModel.bind(context: modelContext)
                if reviews.isEmpty {
                    await viewModel.refresh()
                }
            }
            .overlay(alignment: .top) { refreshBanner }
        }
    }

    // MARK: Feed list

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(reviews) { review in
                    NavigationLink {
                        ReviewDetailView(review: review)
                    } label: {
                        ReviewCard(review: review)
                    }
                    .buttonStyle(.plain)
                    // Subtle spring on first appearance — cinematic feel.
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: reviews.count)
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.5))
            Text("No reviews yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text("Pull to refresh")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: Subtle refresh banner when an error surfaces

    @ViewBuilder
    private var refreshBanner: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.red.opacity(0.85))
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Background

    /// A subtle vertical gradient with a warm low-contrast top — evokes
    /// cinema curtain lighting without stealing attention from the cards.
    private var cinematicBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.04, blue: 0.06),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    FeedView()
        .modelContainer(for: Review.self, inMemory: true)
        .preferredColorScheme(.dark)
}
