//
//  StorageSection.swift
//  VILLE
//
//  Settings → Storage: how much room the reviews and the downloaded images
//  take on this iPhone, the limits that keep them from growing without
//  end, and a way to clear the images now. Clearing is harmless: images
//  download again when they're next shown.
//

import SwiftUI
import SwiftData

struct StorageSection: View {
    @Environment(\.modelContext) private var modelContext

    @State private var libraryBytes: Int?
    @State private var downloadBytes: Int?
    @State private var clears = 0

    var body: some View {
        Section {
            LabeledContent("Reviews", value: sizeText(libraryBytes))
            LabeledContent("Images", value: sizeText(downloadBytes))
            Button("Clear images", action: clearImages)
                .disabled(downloadBytes == 0)
                .sensoryFeedback(.success, trigger: clears)
        } header: {
            Text("Storage")
        } footer: {
            Text("Each member keeps their newest \(LibraryTrimmer.reviewsPerMember) reviews, plus every bookmark. Images take up to \(Self.byteText(LocalStorage.downloadLimit)) and download again when needed.")
        }
        .onAppear(perform: measure)
    }

    private func measure() {
        libraryBytes = LocalStorage.libraryBytes(in: modelContext.container)
        downloadBytes = LocalStorage.downloadBytes
    }

    private func clearImages() {
        LocalStorage.clearDownloads()
        clears += 1
        measure()
    }

    /// "8.2 MB", or nothing until measured (or if it couldn't be).
    private func sizeText(_ bytes: Int?) -> String {
        guard let bytes else { return "" }
        return Self.byteText(bytes)
    }

    private static func byteText(_ bytes: Int) -> String {
        Int64(bytes).formatted(.byteCount(style: .file))
    }
}
