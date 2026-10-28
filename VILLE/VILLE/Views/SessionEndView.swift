//
//  SessionEndView.swift
//  VILLE
//
//  The last page of a session: "Fin", like the end of a film. Says what was
//  read and lets the reader go on, but only if they choose to.
//

import SwiftUI

struct SessionEndView: View {
    let reviewCount: Int
    let memberCount: Int
    /// Saved reviews that have never been shown.
    let unreadCount: Int
    let onKeepReading: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            OffsetPrint(step: 2.4) {
                Text(verbatim: "Fin")
                    .font(.system(size: 96, weight: .bold, design: .serif))
                    .italic()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("The end")

            VStack(spacing: 10) {
                Text("^[\(reviewCount) review](inflect: true) by ^[\(memberCount) member](inflect: true).")
                    .font(.system(.title3, design: .serif))
                Text(nextTime)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
            .multilineTextAlignment(.center)

            Button("Keep reading", action: onKeepReading)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.glass)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelBackground)
    }

    private var nextTime: LocalizedStringKey {
        if unreadCount > 0 {
            "^[\(unreadCount) more review](inflect: true) will be waiting next time."
        } else {
            "That's every review saved so far. New ones arrive when your members post."
        }
    }
}

#Preview {
    SessionEndView(reviewCount: 20, memberCount: 6, unreadCount: 34) {}
}
