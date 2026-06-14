import Foundation
import XCTest

/// Targets every shipped catalog mode for visual QA screenshots.
enum GameModeScreenshotTarget: CaseIterable {
    case x01
    case cricket
    case americanCricket
    case baseball
    case killer
    case shanghai
    case mickeyMouse
    case mulligan
    case englishCricket
    case knockout
    case suddenDeath
    case fiftyOneByFives
    case golf
    case football
    case grandNational
    case hareAndHounds
    case fleet
    case raid
    case aroundTheClock
    case aroundTheClock180
    case chaseTheDragon
    case nineLives

    var catalogId: String {
        switch self {
        case .x01: "standard.x01"
        case .cricket: "standard.cricket"
        case .americanCricket: "standard.americanCricket"
        case .baseball: "party.baseball"
        case .killer: "party.killer"
        case .shanghai: "party.shanghai"
        case .mickeyMouse: "party.mickeyMouse"
        case .mulligan: "party.mulligan"
        case .englishCricket: "party.englishCricket"
        case .knockout: "party.knockout"
        case .suddenDeath: "party.suddenDeath"
        case .fiftyOneByFives: "party.fiftyOneByFives"
        case .golf: "party.golf"
        case .football: "party.football"
        case .grandNational: "party.grandNational"
        case .hareAndHounds: "party.hareAndHounds"
        case .fleet: "party.fleet"
        case .raid: "coop.raid"
        case .aroundTheClock: "practice.aroundTheClock"
        case .aroundTheClock180: "practice.aroundTheClock180"
        case .chaseTheDragon: "practice.chaseTheDragon"
        case .nineLives: "practice.nineLives"
        }
    }

    var folderName: String {
        catalogId.split(separator: ".").last.map(String.init) ?? catalogId
    }

    var displayName: String {
        switch self {
        case .x01: "X01"
        case .cricket: "Cricket"
        case .americanCricket: "American Cricket"
        case .baseball: "Baseball"
        case .killer: "Killer"
        case .shanghai: "Shanghai"
        case .mickeyMouse: "Mickey Mouse"
        case .mulligan: "Mulligan"
        case .englishCricket: "English Cricket"
        case .knockout: "Knockout"
        case .suddenDeath: "Sudden Death"
        case .fiftyOneByFives: "51 by 5's"
        case .golf: "Golf"
        case .football: "Football"
        case .grandNational: "Grand National"
        case .hareAndHounds: "Hare and Hounds"
        case .fleet: "Fleet"
        case .raid: "Raid"
        case .aroundTheClock: "Around the Clock"
        case .aroundTheClock180: "180 Around the Clock"
        case .chaseTheDragon: "Chase the Dragon"
        case .nineLives: "Nine Lives"
        }
    }

    var playerCount: Int {
        switch self {
        case .x01:
            2
        case .aroundTheClock, .aroundTheClock180, .chaseTheDragon, .raid:
            minimumPlayers
        default:
            max(minimumPlayers, 2)
        }
    }

    var minimumPlayers: Int {
        switch self {
        case .x01, .raid, .aroundTheClock, .aroundTheClock180, .chaseTheDragon:
            1
        case .killer, .suddenDeath:
            3
        default:
            2
        }
    }
}

enum GameModeScreenshotVariant: String, CaseIterable {
    case portrait
    case landscape
    case massiveTextPortrait = "massive-text-portrait"
    case massiveTextLandscape = "massive-text-landscape"

    var usesAccessibilityTextSize: Bool {
        switch self {
        case .portrait, .landscape: false
        case .massiveTextPortrait, .massiveTextLandscape: true
        }
    }

    var isLandscape: Bool {
        switch self {
        case .landscape, .massiveTextLandscape: true
        case .portrait, .massiveTextPortrait: false
        }
    }
}

enum GameModeScreenshotWriter {
    static let outputDirectoryEnvironmentKey = "GAME_MODE_SCREENSHOT_OUTPUT_DIR"
    static let outputDirectoryMarkerFileName = ".game-mode-screenshot-output-path"

    static func outputDirectory() throws -> URL {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // UI
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root

        let markerFile = repoRoot.appendingPathComponent(outputDirectoryMarkerFileName)
        if let markerPath = try? String(contentsOf: markerFile, encoding: .utf8) {
            let trimmed = markerPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return URL(fileURLWithPath: trimmed, isDirectory: true)
            }
        }

        if let raw = ProcessInfo.processInfo.environment[outputDirectoryEnvironmentKey],
           !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }

        return repoRoot
            .appendingPathComponent("Screenshots/game-modes/latest", isDirectory: true)
    }

    static func writeManifest(
        to root: URL,
        captures: [(mode: GameModeScreenshotTarget, variant: GameModeScreenshotVariant, path: URL)],
        simulatorName: String
    ) throws {
        let payload: [String: Any] = [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "simulatorName": simulatorName,
            "captureCount": captures.count,
            "modes": GameModeScreenshotTarget.allCases.map { mode in
                [
                    "catalogId": mode.catalogId,
                    "folder": mode.folderName,
                    "displayName": mode.displayName,
                    "screenshots": GameModeScreenshotVariant.allCases.compactMap { variant in
                        captures.first(where: { $0.mode == mode && $0.variant == variant }).map { entry in
                            [
                                "variant": variant.rawValue,
                                "path": entry.path.path
                                    .replacingOccurrences(of: root.path + "/", with: "")
                            ]
                        }
                    }
                ] as [String: Any]
            }
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: root.appendingPathComponent("manifest.json"))
    }
}

extension DartBuddyUITestCase {
    func launchForGameModeScreenshots(usesAccessibilityTextSize: Bool) -> XCUIApplication {
        var arguments = [
            "-enable_full_product_surface",
            "-seed_players",
            Self.disableFeedbackLaunchArgument,
        ]
        if usesAccessibilityTextSize {
            arguments.append("-ui_test_accessibility_text_size")
        }
        let app = launchApp(arguments)
        ensurePlayTab(app, timeout: timeout + 20)
        XCTAssertTrue(
            app.buttons["select_Alice"].waitForExistence(timeout: timeout + 30),
            "seed_players should expose Alice on the roster"
        )
        return app
    }

    func configureGameModeForScreenshot(_ mode: GameModeScreenshotTarget, in app: XCUIApplication) {
        // Default Play setup presets are sufficient for visual QA captures.
        _ = mode
        _ = app
    }

    func selectMinimumPlayers(for mode: GameModeScreenshotTarget, in app: XCUIApplication) {
        let roster = ["Alice", "Bob", "Carol"]
        for index in 0 ..< mode.playerCount {
            ensurePlayerSelectedFromRoster(roster[index], in: app, timeout: timeout + 10)
        }
    }

    private func ensurePlayerSelectedFromRoster(_ name: String, in app: XCUIApplication, timeout: TimeInterval) {
        let staged = app.descendants(matching: .any)["setup_selected_\(name)"].firstMatch
        if staged.waitForExistence(timeout: 2) { return }
        selectPlayerFromRoster(name, in: app, timeout: timeout)
    }

    func waitForGameModeMatchBoard(_ mode: GameModeScreenshotTarget, in app: XCUIApplication) {
        let wait = timeout + 30
        let exit = app.buttons["match_exit"]
        switch mode {
        case .x01:
            _ = waitForPadReady(app, timeout: wait)
        case .cricket, .americanCricket:
            waitForCricketScoringPadReady(app, timeout: wait)
        case .baseball:
            _ = app.descendants(matching: .any)["baseball_match_header"].waitForExistence(timeout: wait)
        case .shanghai:
            _ = app.descendants(matching: .any)["shanghai_match_header"].waitForExistence(timeout: wait)
        case .killer:
            _ = app.descendants(matching: .any)["killer_match_header"].waitForExistence(timeout: wait)
        case .mickeyMouse:
            _ = app.descendants(matching: .any)["mickeyMouse_match_header"].waitForExistence(timeout: wait)
        case .mulligan:
            _ = app.descendants(matching: .any)["mulligan_match_header"].waitForExistence(timeout: wait)
        case .englishCricket:
            _ = app.descendants(matching: .any)["englishCricket_match_header"].waitForExistence(timeout: wait)
        case .knockout:
            _ = app.descendants(matching: .any)["knockout_match_header"].waitForExistence(timeout: wait)
        case .suddenDeath:
            _ = app.descendants(matching: .any)["suddenDeath_match_header"].waitForExistence(timeout: wait)
        case .fiftyOneByFives:
            _ = app.descendants(matching: .any)["fiftyOneByFives_match_header"].waitForExistence(timeout: wait)
        case .golf:
            _ = app.descendants(matching: .any)["golf_match_header"].waitForExistence(timeout: wait)
        case .football:
            _ = app.descendants(matching: .any)["football_match_header"].waitForExistence(timeout: wait)
        case .grandNational:
            _ = app.descendants(matching: .any)["grandNational_match_header"].waitForExistence(timeout: wait)
        case .hareAndHounds:
            _ = app.descendants(matching: .any)["hareAndHounds_match_header"].waitForExistence(timeout: wait)
        case .aroundTheClock:
            _ = app.descendants(matching: .any)["aroundTheClock_match_header"].waitForExistence(timeout: wait)
        case .aroundTheClock180:
            _ = app.descendants(matching: .any)["atc180_match_header"].waitForExistence(timeout: wait)
        case .chaseTheDragon:
            _ = app.descendants(matching: .any)["chaseTheDragon_match_header"].waitForExistence(timeout: wait)
        case .nineLives:
            _ = app.descendants(matching: .any)["nineLives_match_header"].waitForExistence(timeout: wait)
        case .fleet:
            let handoff = app.buttons["fleet_handoff_confirm"]
            XCTAssertTrue(
                handoff.waitForExistence(timeout: wait) || exit.waitForExistence(timeout: wait),
                "Fleet should show handoff or gameplay chrome"
            )
            return
        case .raid:
            break
        }
        XCTAssertTrue(
            exit.waitForExistence(timeout: wait),
            "\(mode.displayName) match screen should expose match_exit"
        )
    }

    func selectCatalogModeCard(_ catalogId: String, in app: XCUIApplication, timeout: TimeInterval) {
        ensurePlayTab(app, timeout: timeout)
        let changeButton = app.buttons["setup_changeModeButton"]
        XCTAssertTrue(changeButton.waitForExistence(timeout: timeout), "Expected Change mode button")
        changeButton.tap()

        let searchField = app.textFields["modesSearchField"]
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.clearAndEnterText(catalogSearchTerm(for: catalogId))
            if app.keyboards.buttons["Search"].waitForExistence(timeout: 1) {
                app.keyboards.buttons["Search"].tap()
            } else if app.keyboards.buttons["Return"].waitForExistence(timeout: 1) {
                app.keyboards.buttons["Return"].tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }

        let card = app.descendants(matching: .any)["modes_card_\(catalogId)"]
        if !card.waitForExistence(timeout: 3) {
            for _ in 0 ..< 8 where card.exists == false {
                app.swipeUp()
            }
        }
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "Expected picker card \(catalogId)")
        if card.isHittable {
            card.tap()
        } else {
            card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        ensurePlayTab(app, timeout: timeout)
    }

    private func catalogSearchTerm(for catalogId: String) -> String {
        switch catalogId {
        case "standard.x01": "X01"
        case "standard.cricket": "Cricket"
        case "standard.americanCricket": "American"
        case "party.mickeyMouse": "Mickey"
        case "party.fiftyOneByFives": "51"
        case "party.hareAndHounds": "Hare"
        case "practice.aroundTheClock": "Around"
        case "practice.aroundTheClock180": "180"
        case "practice.chaseTheDragon": "Dragon"
        case "practice.nineLives": "Nine"
        default:
            catalogId.split(separator: ".").last.map(String.init) ?? catalogId
        }
    }

    func startGameModeMatch(_ mode: GameModeScreenshotTarget, in app: XCUIApplication) {
        ensurePlayTab(app, timeout: timeout)
        selectCatalogModeCard(mode.catalogId, in: app, timeout: timeout + 10)
        configureGameModeForScreenshot(mode, in: app)
        selectMinimumPlayers(for: mode, in: app)
        tapStartMatch(in: app, timeout: timeout + 10)
        waitForGameModeMatchBoard(mode, in: app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }

    @discardableResult
    func captureGameModeScreenshot(
        mode: GameModeScreenshotTarget,
        variant: GameModeScreenshotVariant,
        rootDirectory: URL
    ) throws -> URL {
        let modeDirectory = rootDirectory.appendingPathComponent(mode.folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modeDirectory, withIntermediateDirectories: true)
        let fileURL = modeDirectory.appendingPathComponent("\(variant.rawValue).png")
        let screenshot = XCUIScreen.main.screenshot()
        try screenshot.pngRepresentation.write(to: fileURL)
        return fileURL
    }

    func applyScreenshotOrientation(_ variant: GameModeScreenshotVariant, app: XCUIApplication) {
        if variant.isLandscape {
            rotateToLandscapeLeftForTest(app: app, timeout: timeout)
        } else {
            resetSimulatorOrientationToPortrait()
            RunLoop.current.run(until: Date().addingTimeInterval(0.75))
        }
    }

    func abandonMatchForScreenshots(in app: XCUIApplication) {
        let exit = app.buttons["match_exit"]
        guard exit.waitForExistence(timeout: timeout) else { return }
        exit.tap()
        let abandon = app.descendants(matching: .any).matching(identifier: "match_exit_abandon").firstMatch
        if abandon.waitForExistence(timeout: timeout) {
            abandon.tap()
        }
        _ = app.buttons["startMatchButton"].waitForExistence(timeout: timeout + 15)
            || app.buttons["select_Alice"].waitForExistence(timeout: timeout + 15)
    }
}
