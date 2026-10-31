//
//  LibraryTrimmer.swift
//  VILLE
//
//  Keeps the saved library from growing without end. Each followed member
//  keeps their newest `reviewsPerMember` reviews; older ones are deleted.
//  Bookmarked reviews are always kept, outside that count. Reviews left
//  behind by a removed member (a bookmark that was taken off afterwards)
//  are deleted too.
//
//  Deletes but doesn't save — the caller owns the save.
//

import Foundation
import SwiftData

struct LibraryTrimmer {
    /// Twice an RSS window (about 50 diary entries), so the library still
    /// reaches past what Letterboxd's feed holds, but stops somewhere.
    static let reviewsPerMember = 100

    /// Returns how many reviews were deleted. Throws only if the library
    /// can't be read, and then deletes nothing.
    func trim(in context: ModelContext) throws -> Int {
        let followed = Set(try context.fetch(FetchDescriptor<FollowedUser>()).map(\.username))
        let descriptor = FetchDescriptor<Review>(
            predicate: #Predicate { $0.bookmarkedAt == nil },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        let unbookmarked = try context.fetch(descriptor)

        // Newest first, so each member's first `reviewsPerMember` are kept.
        var keptPerMember: [String: Int] = [:]
        var deleted = 0
        for review in unbookmarked {
            let kept = keptPerMember[review.username, default: 0]
            guard followed.contains(review.username), kept < Self.reviewsPerMember else {
                context.delete(review)
                deleted += 1
                continue
            }
            keptPerMember[review.username] = kept + 1
        }
        return deleted
    }
}
