//
//  FollowingBadge.swift
//  VILLE
//
//  "Following", where Follow was: on the member Search found, and in the
//  bar over a member's feed. Not a button: unfollowing happens in People,
//  or from a reel's byline in the feed.
//

import SwiftUI

struct FollowingBadge: View {
    /// The label's height inside the glass: 24 in a bar, beside 44-point
    /// buttons. Nil sizes it like a glass button in a list.
    var labelHeight: CGFloat? = nil

    var body: some View {
        Label {
            Text(String(localized: "member.following", defaultValue: "Following", comment: "Shown where Follow was, once the reader follows this member."))
        } icon: {
            Image(systemName: "checkmark")
        }
        .frame(height: labelHeight)
        .padding(.horizontal, 14)
        .padding(.vertical, labelHeight == nil ? 7 : 10)
        .glassEffect()
    }
}
