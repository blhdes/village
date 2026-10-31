//
//  ReelTextBox.swift
//  VILLE
//
//  A reel's review text, in the space between the header and the actions.
//  If the text is taller than that space, it fades out and a "Continue
//  reading" button opens the full reader. Shows the translation when the
//  reader asked for one (`ReviewTranslator`).
//

import SwiftUI

struct ReelTextBox: View {
    let review: Review
    /// The reader sheet zooms out of the "Continue reading" button.
    let readerNamespace: Namespace.ID
    let onContinueReading: () -> Void

    @Environment(ReviewTranslator.self) private var translator

    @State private var contentHeight: CGFloat = 0
    @State private var boxHeight: CGFloat = 0

    private var isOverflowing: Bool { contentHeight > boxHeight + 1 }

    var body: some View {
        ReviewTextView(blocks: translator.blocks(for: review))
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            // minHeight: 0 lets the box stay smaller than the text, so long
            // reviews get clipped instead of pushing the buttons off screen.
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { boxHeight = $0 }
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: isOverflowing ? 0.75 : 1),
                        .init(color: isOverflowing ? .clear : .black, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                if isOverflowing {
                    Button("Continue reading", action: onContinueReading)
                        .font(.system(.subheadline, design: .serif, weight: .medium).italic())
                        .buttonStyle(.glass)
                        .matchedTransitionSource(id: review.id, in: readerNamespace)
                }
            }
            .contentShape(.rect)
            // Tapping a cut-off review opens the reader. Only switched on
            // when the text is cut off, so links in a short review keep
            // their own tap (the reader has them all).
            .gesture(
                TapGesture().onEnded(onContinueReading),
                including: isOverflowing ? .all : .subviews
            )
    }
}
