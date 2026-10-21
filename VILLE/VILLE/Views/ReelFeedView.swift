//
//  ReelFeedView.swift
//  VILLE
//
//  Main screen: full-screen reviews you swipe through vertically, one per
//  page, in the order kept by `ReelQueue`.
//

import SwiftUI
import SwiftData

struct ReelFeedView: View {
    @Environment(FeedViewModel.self) private var viewModel

    @Query private var reviews: [Review]
    @Query private var members: [FollowedUser]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = true

    @State private var currentSlotID: Int?
    @State private var activeSheet: Sheet?

    private enum Sheet: String, Identifiable {
        case members, settings
        var id: String { rawValue }
    }

    private var reviewIDs: [String] { reviews.map(\.id) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.queue.slots.isEmpty {
                    emptyState
                } else {
                    reels(insets: proxy.safeAreaInsets)
                }
            }
        }
        .overlay(alignment: .top) { topBar }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .members: MembersView()
            case .settings: SettingsView()
            }
        }
        .task { await viewModel.refreshIfNeeded() }
        .onChange(of: reviewIDs, initial: true) { _, ids in
            viewModel.syncQueue(with: ids)
        }
        .onChange(of: currentSlotID) { _, slotID in
            guard let slotID else { return }
            viewModel.didShowSlot(slotID, reviewIDs: reviewIDs)
        }
        .sensoryFeedback(.selection, trigger: currentSlotID)
    }

    // MARK: Reels

    private func reels(insets: EdgeInsets) -> some View {
        let lookup = Dictionary(reviews.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.queue.slots) { slot in
                    Group {
                        if let review = lookup[slot.reviewID] {
                            ReelView(
                                review: review,
                                showPoster: showPosters,
                                showBackdrop: showBackdrops,
                                insets: insets
                            )
                        } else {
                            Color.black
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentSlotID)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Text("VILLE")
                .font(.system(.headline, design: .serif, weight: .bold))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 8)

            Spacer()

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    barButton("person.2", label: "People") { activeSheet = .members }
                    barButton("slider.horizontal.3", label: "Settings") { activeSheet = .settings }
                }
            }
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) { errorBanner.offset(y: 52) }
    }

    private func barButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(.red.opacity(0.4)), in: .capsule)
                .onTapGesture { viewModel.errorMessage = nil }
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Empty states

    @ViewBuilder
    private var emptyState: some View {
        if members.isEmpty {
            emptyMessage(
                icon: "text.quote",
                title: "Reviews, one at a time",
                message: "Add the Letterboxd members whose writing you want to read.",
                buttonTitle: "Add people"
            )
        } else if viewModel.isRefreshing {
            VStack(spacing: 14) {
                ProgressView()
                Text("Fetching reviews…")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        } else {
            emptyMessage(
                icon: "text.page.slash",
                title: "No written reviews yet",
                message: "The people you follow haven't posted reviews recently. Add more people to fill your feed.",
                buttonTitle: "Add people"
            )
        }
    }

    private func emptyMessage(icon: String, title: String, message: String, buttonTitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.5))
            Text(title)
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(buttonTitle) { activeSheet = .members }
                .buttonStyle(.glassProminent)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Review.self, FollowedUser.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    ReelFeedView()
        .environment(FeedViewModel(context: container.mainContext))
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
