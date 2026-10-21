//
//  FollowedUser.swift
//  VILLE
//
//  A Letterboxd member whose public reviews the user wants to read.
//  Stored only on the device — VILLE has no accounts.
//

import Foundation
import SwiftData

@Model
final class FollowedUser {
    /// Lowercase Letterboxd handle — the part after letterboxd.com/.
    @Attribute(.unique) var username: String

    /// Name shown on Letterboxd, refreshed from the RSS feed.
    var displayName: String

    var addedAt: Date

    init(username: String, displayName: String, addedAt: Date = .now) {
        self.username = username
        self.displayName = displayName
        self.addedAt = addedAt
    }

    var profileURL: URL? { URL(string: "https://letterboxd.com/\(username)/") }
}
