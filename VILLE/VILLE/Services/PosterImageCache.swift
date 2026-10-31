//
//  PosterImageCache.swift
//  VILLE
//
//  Posters decoded and kept in memory, so a poster already seen (or fetched
//  ahead, like the one the next tap will show) appears at once, with no
//  loading state in between. Downloads go through URLSession, so the
//  shared URLCache (`LocalStorage`) still keeps them on disk between launches.
//

import Foundation
import ImageIO

final class PosterImageCache {
    static let shared = PosterImageCache()

    private let memory = NSCache<NSURL, Entry>()
    /// Loads already running, so two views asking for one poster share it.
    private var inFlight: [URL: Task<Entry?, Never>] = [:]

    private init() {
        // About 40 posters at w342 (≈0.7 MB each once decoded).
        memory.countLimit = 40
    }

    /// The poster, if it's already in memory.
    func image(for url: URL) -> CGImage? {
        memory.object(forKey: url as NSURL)?.image
    }

    /// Downloads and decodes the poster, or joins a load already running.
    /// Returns nil if it can't be loaded (the reason is logged).
    func load(_ url: URL) async -> CGImage? {
        if let cached = image(for: url) { return cached }
        if let running = inFlight[url] { return await running.value?.image }

        let task = Task { await Self.download(url) }
        inFlight[url] = task
        let loaded = await task.value
        inFlight[url] = nil
        if let loaded {
            memory.setObject(loaded, forKey: url as NSURL)
        }
        return loaded?.image
    }

    /// Forgets every decoded poster (Settings → Storage → Clear images).
    /// Posters already on screen keep their own copy.
    func removeAll() {
        memory.removeAllObjects()
    }

    /// Starts loading without waiting for it.
    func prefetch(_ url: URL?) {
        guard let url, image(for: url) == nil, inFlight[url] == nil else { return }
        Task { _ = await load(url) }
    }

    /// The download and the decode, off the main thread.
    @concurrent
    private nonisolated static func download(_ url: URL) async -> Entry? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("PosterImageCache: \(url) answered \(http.statusCode)")
                return nil
            }
            // Decoded now rather than on first draw, so showing it never stutters.
            let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, options) else {
                print("PosterImageCache: couldn't decode \(url)")
                return nil
            }
            return Entry(image)
        } catch {
            print("PosterImageCache: loading \(url) failed — \(error)")
            return nil
        }
    }

    /// A decoded poster. Images never change once made, so it's safe to
    /// hand from the download thread to the main one.
    private final class Entry: @unchecked Sendable {
        let image: CGImage
        nonisolated init(_ image: CGImage) { self.image = image }
    }
}
