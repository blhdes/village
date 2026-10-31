//
//  LocalStorage.swift
//  VILLE
//
//  How much room VILLE takes on the iPhone, and the limit on downloads.
//  Two things take space: the library (reviews in SwiftData, kept in check
//  by `LibraryTrimmer`) and the download cache (posters, backdrops, TMDB
//  and RSS answers), which never grows past `downloadLimit`.
//

import Foundation
import SwiftData

enum LocalStorage {
    /// The most the download cache keeps on disk. It lives in Caches, so
    /// iOS can also clear it when the iPhone runs low on space; anything
    /// gone downloads again when it's next shown.
    static let downloadLimit = 150_000_000

    /// Decoded images held in memory while the app runs.
    private static let memoryLimit = 50_000_000

    /// AsyncImage, posters, TMDB and RSS all go through `URLSession.shared`,
    /// so one cache holds every download, and one limit covers them all.
    static func configureDownloadCache() {
        URLCache.shared = URLCache(memoryCapacity: memoryLimit, diskCapacity: downloadLimit)
    }

    /// The download cache's size on disk, in bytes. Mostly images.
    static var downloadBytes: Int {
        URLCache.shared.currentDiskUsage
    }

    /// Empties the download cache and the decoded posters. Images already
    /// on screen stay; the rest download again when needed.
    static func clearDownloads() {
        URLCache.shared.removeAllCachedResponses()
        PosterImageCache.shared.removeAll()
    }

    /// The library's size on disk, in bytes: the SwiftData store plus its
    /// journal files. Nil if the store can't be found.
    static func libraryBytes(in container: ModelContainer) -> Int? {
        guard let store = container.configurations.first?.url else {
            print("LocalStorage: the SwiftData container has no store URL")
            return nil
        }
        let path = store.path(percentEncoded: false)
        // The journal files only exist while SQLite needs them.
        let files = [path, path + "-wal", path + "-shm"].filter { FileManager.default.fileExists(atPath: $0) }

        return files.reduce(0) { total, path in
            do {
                let values = try URL(filePath: path).resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                return total + (values.totalFileAllocatedSize ?? 0)
            } catch {
                print("LocalStorage: could not read the size of \(path) — \(error)")
                return total
            }
        }
    }
}
