//
//  MembersView.swift
//  VILLE
//
//  The Letterboxd members whose reviews fill the feed, saved only on this
//  device. At the top, Search (`MemberSearchSection`): find a member by
//  username or link, read their reviews first (`MemberFeedView`) or follow
//  them. Tapping a name in Suggested or Following opens their reviews too.
//  Until the user follows a few people, a "Suggested" section offers some
//  to start with. Bookmarks open from here too: one quiet row, the user's
//  own corner of the library, with a monochrome icon like the rows in
//  Settings. Swiping a name in Following left unfollows, after asking,
//  as the reel's byline does.
//

import SwiftUI
import SwiftData

/// Screens pushed from People. By value, like the reviews pushed from
/// Bookmarks: mixing view links and value links in one stack can pop the
/// Bookmarks list when a review opens.
private enum PeopleRoute: Hashable {
    case bookmarks
}

struct MembersView: View {
    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FollowedUser.addedAt, order: .reverse) private var members: [FollowedUser]
    @Query(filter: #Predicate<Review> { $0.bookmarkedAt != nil }) private var bookmarks: [Review]

    /// A member's reviews, open over People.
    @State private var visit: MemberVisit?
    /// The member a swipe asked to unfollow, waiting for the reader's OK.
    @State private var unfollowing: String?
    @State private var follows = 0
    @State private var unfollows = 0

    private var following: Set<String> {
        Set(members.map(\.username))
    }

    var body: some View {
        NavigationStack {
            List {
                MemberSearchSection(
                    following: following,
                    onFollowed: { follows += 1 },
                    onRead: { member in
                        visit = MemberVisit(username: member.username, displayName: member.displayName, fetchesFeed: false)
                    }
                )

                if members.count < SuggestedMember.enoughMembers {
                    SuggestedMembersSection(
                        following: following,
                        onFollowed: { follows += 1 },
                        onRead: { suggestion in
                            visit = MemberVisit(username: suggestion.username, displayName: suggestion.displayName, fetchesFeed: true)
                        }
                    )
                }

                Section {
                    NavigationLink(value: PeopleRoute.bookmarks) {
                        LabeledContent {
                            if !bookmarks.isEmpty {
                                Text(bookmarks.count, format: .number)
                            }
                        } label: {
                            Label {
                                Text("Bookmarks")
                                    .font(.system(.body, design: .serif))
                            } icon: {
                                Image(systemName: "bookmark")
                            }
                        }
                    }
                }

                if !members.isEmpty {
                    Section("Following") {
                        ForEach(members) { member in
                            memberRow(member)
                        }
                    }
                }
            }
            .navigationDestination(for: PeopleRoute.self) { _ in
                BookmarksView()
            }
            .editorialTitle("People")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: follows)
            .sensoryFeedback(.selection, trigger: unfollows)
            .fullScreenCover(item: $visit) { visit in
                MemberFeedView(visit: visit)
            }
        }
    }

    /// A followed member: the name opens their reviews, the arrow their
    /// profile on Letterboxd. Swiping left unfollows, after asking.
    private func memberRow(_ member: FollowedUser) -> some View {
        // Plain copies for the question: unfollowing deletes the member,
        // and the question must not read it while it closes.
        let username = member.username
        let name = member.displayName

        return HStack {
            // Borderless, so the name and the arrow each keep their own tap
            // instead of the whole row firing both.
            Button {
                visit = MemberVisit(username: member.username, displayName: member.displayName, fetchesFeed: false)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.displayName)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Color.primary)
                    Text("@\(member.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Opens their reviews")

            if let profileURL = member.profileURL {
                Link(destination: profileURL) {
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Open \(member.displayName) on Letterboxd")
            }
        }
        // Unfollow, not the system's Delete: "Follow" is the verb
        // everywhere. Not a destructive role either: that would slide the
        // row away before the reader confirms.
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                unfollowing = username
            } label: {
                Label("Unfollow", systemImage: "person.badge.minus")
            }
            .tint(.red)
        }
        // Unfollowing also deletes their saved reviews: ask first. On the
        // row, not the list, so the question opens beside this name.
        .confirmationDialog(
            Text("Unfollow \(name)?"),
            isPresented: isUnfollowing(username),
            titleVisibility: .visible
        ) {
            Button("Unfollow", role: .destructive) { unfollow(member) }
        } message: {
            Text("Their reviews leave your feed and this iPhone. The ones you bookmarked stay in Bookmarks.")
        }
    }

    /// Only the swiped row's question is up.
    private func isUnfollowing(_ username: String) -> Binding<Bool> {
        Binding(
            get: { unfollowing == username },
            set: { if !$0 { unfollowing = nil } }
        )
    }

    /// Their row slides out and their saved reviews go, bookmarks apart.
    private func unfollow(_ member: FollowedUser) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.removeMembers([member])
        }
        unfollows += 1
    }
}
