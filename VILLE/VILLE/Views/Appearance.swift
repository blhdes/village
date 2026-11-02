//
//  Appearance.swift
//  VILLE
//
//  The light/dark choice from Settings, and its picker: three small pages
//  with the wordmark, like iOS's Display & Brightness. The reel background
//  that follows it is the `ReelBackground` color asset
//  (`Color.reelBackground`): white in light mode, pure black in dark mode,
//  also inside sheets.
//

import SwiftUI

/// Appearance picked in Settings. `system` follows the phone.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` hands the choice back to iOS.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Settings → Look: each appearance as a small page with the wordmark in
/// its colors (System split corner to corner between both), and a check
/// under the one in use.
struct AppearancePicker: View {
    @Binding var selection: Appearance

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Appearance.allCases) { option in
                choice(option)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func choice(_ option: Appearance) -> some View {
        let isSelected = option == selection

        return Button {
            selection = option
        } label: {
            VStack(spacing: 8) {
                AppearanceSwatch(option: option)
                Text(option.title)
                    .font(.footnote)
                // 0.6 keeps the empty circle at 3:1 or better, as icons need.
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.6))
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(option.title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// One appearance in miniature: the wordmark on a reel's page.
private struct AppearanceSwatch: View {
    let option: Appearance

    private let corner: CGFloat = 12

    var body: some View {
        Group {
            switch option {
            case .light:
                page(.light)
            case .dark:
                page(.dark)
            case .system:
                page(.light)
                    .overlay {
                        page(.dark).mask { LowerRightHalf() }
                    }
            }
        }
        .frame(height: 64)
        .clipShape(.rect(cornerRadius: corner))
        // In the screen's own colors, so a white page shows on white.
        .overlay {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
        }
    }

    /// The page and the wordmark as they look in one color scheme.
    private func page(_ scheme: ColorScheme) -> some View {
        Color.reelBackground
            .overlay { VILLEWordmark(size: 20) }
            .environment(\.colorScheme, scheme)
    }
}

/// The lower right half of a rectangle, cut corner to corner.
private struct LowerRightHalf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
