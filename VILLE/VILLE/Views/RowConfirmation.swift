//
//  RowConfirmation.swift
//  VILLE
//
//  The question a list row asks before it goes: removing a bookmark,
//  unfollowing someone. It hangs on the row itself, because iOS 26 draws
//  a confirmation as a popover pointing at the view it hangs from: on the
//  whole list it opens at the top, away from the row.
//
//  The answer runs once the question has closed. A row removed at once
//  takes its question with it, still marked open, and iOS shows it again
//  for an instant over the empty place.
//

import SwiftUI

extension View {
    /// Asks `title` beside this row. The destructive `confirm` button
    /// closes the question, then runs `action`.
    func rowConfirmation<Message: View>(
        _ title: Text,
        isPresented: Binding<Bool>,
        confirm: LocalizedStringKey,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder message: () -> Message
    ) -> some View {
        let message = message()
        return confirmationDialog(title, isPresented: isPresented, titleVisibility: .visible) {
            Button(confirm, role: .destructive) {
                isPresented.wrappedValue = false
                Task {
                    do {
                        try await Task.sleep(for: RowConfirmation.closing)
                    } catch {
                        print("RowConfirmation: the wait for the question to close failed: \(error)")
                        return
                    }
                    action()
                }
            }
        } message: {
            message
        }
    }
}

private enum RowConfirmation {
    /// About as long as iOS takes to close the question.
    static let closing: Duration = .milliseconds(300)
}
