//
//  StoreShots.swift
//  VILLEStoreShots
//
//  Takes VILLE's App Store screenshots on the iPhone (store/SCREENSHOTS.md).
//  Each shot launches VILLE in demo mode (`-StoreScreenshots <shot>`, see
//  StoreDemo.swift), goes where the shot is, and keeps the screen as an
//  attachment named after the shot. store/screenshots/capture.sh runs it
//  once per language and saves the attachments as
//  raw/<language>/<shot>.png.
//

import XCTest

// nonisolated: XCTestCase isn't on the main actor, even where a target
// puts everything else there by default. The steps that drive VILLE are.
nonisolated final class StoreShots: XCTestCase {
    /// The shots, in store order. The names match `StoreShot` in the app.
    private let shots = ["1-reel", "2-words", "3-spoiler", "4-fin", "5-translation", "6-people", "7-settings"]

    @MainActor
    func testStoreScreens() throws {
        // One shot gone wrong spoils the set: stop there.
        continueAfterFailure = false

        for shot in shots {
            let app = launch(shot)
            // The top bar is there once the feed is.
            XCTAssertTrue(app.buttons["people"].waitForExistence(timeout: 15), "\(shot): the feed didn't appear")

            switch shot {
            case "4-fin":
                try swipeToFin(in: app)
            case "6-people":
                app.buttons["people"].tap()
            case "7-settings":
                app.buttons["settings"].tap()
            default:
                break
            }

            // Sheets finish their zoom, backdrops fade in (0.4 s).
            settle(2.5)
            keep(shot)
            app.terminate()
        }
    }

    // MARK: Steps

    /// Launches VILLE in demo mode, in the run's language (capture.sh sets
    /// STORE_LANGUAGE and STORE_REGION through TEST_RUNNER_ variables).
    /// Without them (a run from Xcode), VILLE keeps the test's own
    /// language instead of falling back to English.
    @MainActor
    private func launch(_ shot: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-StoreScreenshots", shot]

        let environment = ProcessInfo.processInfo.environment
        if let language = environment["STORE_LANGUAGE"], let region = environment["STORE_REGION"] {
            let locale = language.split(separator: "-").first.map(String.init) ?? language
            app.launchArguments += [
                "-AppleLanguages", "(\(language))",
                "-AppleLocale", "\(locale)_\(region)",
            ]
        } else {
            print("StoreShots: no STORE_LANGUAGE/STORE_REGION, VILLE runs in the test's language")
        }
        app.launch()
        return app
    }

    /// Reads through the session to its end card, a reel at a time, as a
    /// reader would.
    @MainActor
    private func swipeToFin(in app: XCUIApplication) throws {
        let fin = app.descendants(matching: .any)["fin"]
        for _ in 0..<12 {
            if fin.exists { return }
            app.swipeUp()
            settle(0.8)
        }
        XCTAssertTrue(fin.waitForExistence(timeout: 3), "4-fin: never reached the end card")
    }

    @MainActor
    private func keep(_ shot: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = shot
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Waits without expecting anything.
    @MainActor
    private func settle(_ seconds: TimeInterval) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }
}
