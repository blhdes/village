//
//  TranslationNote.swift
//  VILLE
//
//  The line under a review's dateline when it's written in another
//  language: "Translate from English". One tap swaps the text in place for
//  the iPhone's language, and the note becomes a translator's credit, as a
//  book prints it: "Translated from English · Show original". Shown in
//  the reel and the full reader (it lives in `ReviewHeader`).
//

import SwiftUI
import Translation

struct TranslationNote: View {
    let review: Review

    @Environment(ReviewTranslator.self) private var translator

    /// Set on the first tap. It starts `.translationTask`, which hands over a
    /// session (asking to download the languages first, if needed).
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        if let source = translator.sourceLanguage(for: review) {
            let state = translator.state(for: review)
            Button {
                toggle(from: source, state: state)
            } label: {
                label(for: state, language: ReviewTranslation.name(of: source))
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint(state == .translated ? "Shows the review as written" : "Translates the review into your iPhone's language")
            .sensoryFeedback(.selection, trigger: state == .translated)
            .translationTask(configuration) { session in
                await translator.translate(review, using: session)
            }
        }
    }

    @ViewBuilder
    private func label(for state: ReviewTranslator.State, language: String) -> some View {
        switch state {
        case .original:
            Text("Translate from \(language)")
        case .translating:
            BreathingText(text: "Translating…")
        case .translated:
            Text("Translated from \(language) · Show original")
        }
    }

    private func toggle(from source: Locale.Language, state: ReviewTranslator.State) {
        // Not `.disabled`: that would dim the breathing "Translating…".
        guard state != .translating else { return }
        if state == .translated {
            translator.showOriginal(of: review)
            return
        }
        if translator.hasTranslation(for: review) {
            translator.showTranslation(of: review)
            return
        }
        // A new configuration starts the task; after a failed try (say, the
        // download was declined) invalidating it runs the task again.
        if configuration == nil {
            configuration = TranslationSession.Configuration(source: source, target: translator.target)
        } else {
            configuration?.invalidate()
        }
    }
}

/// Text that breathes at the wordmark dot's pace while something is on its
/// way, like `LoadingSkeleton`. Holds still with Reduce Motion. It never
/// fades below 0.75, so under the note's 0.8 it stays at the 0.6 floor
/// for secondary text.
private struct BreathingText: View {
    let text: LocalizedStringKey

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PhaseAnimator(reduceMotion ? [1] : [0.75, 1]) { strength in
            Text(text)
                .opacity(strength)
        } animation: { _ in
            .easeInOut(duration: 0.9)
        }
    }
}
