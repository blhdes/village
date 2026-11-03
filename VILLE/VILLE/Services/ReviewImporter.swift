//
//  ReviewImporter.swift
//  VILLE
//
//  Saves a member's parsed RSS feed into the library, matched by review
//  id: new reviews are inserted, saved ones get the fields an author can
//  change after posting. Reviews that dropped out of the RSS window are
//  kept, so the library grows (`LibraryTrimmer` keeps it in check). A
//  followed member's name is refreshed from the feed too.
//
//  Writes but doesn't save — the caller owns the save.
//

import Foundation
import SwiftData

struct ReviewImporter {
    /// Throws only if the library can't be read, and then writes nothing.
    func importFeed(_ feed: UserFeed, for username: String, into context: ModelContext) throws {
        let saved = try context.fetch(FetchDescriptor<Review>(predicate: #Predicate { $0.username == username }))
        let member = try context.fetch(FetchDescriptor<FollowedUser>(predicate: #Predicate { $0.username == username })).first
        let savedByID = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for parsed in feed.reviews {
            if let review = savedByID[parsed.id] {
                review.update(from: parsed)
            } else {
                context.insert(Review(from: parsed))
            }
        }

        if let member, let name = feed.displayName {
            member.displayName = name
        }
    }
}
