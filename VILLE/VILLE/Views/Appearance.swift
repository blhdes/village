//
//  Appearance.swift
//  VILLE
//
//  The light/dark choice from Settings. The reel background that follows it
//  is the `ReelBackground` color asset (`Color.reelBackground`): white in
//  light mode, pure black in dark mode, also inside sheets.
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
