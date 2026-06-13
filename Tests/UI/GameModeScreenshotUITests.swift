import XCTest

/// Captures portrait, landscape, and accessibility Dynamic Type screenshots for every shipped game mode.
/// Run via `./Scripts/capture_game_mode_screenshots.sh`.
final class GameModeScreenshotUITests: DartBuddyUITestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testCaptureAllShippedGameModeScreenshots() throws {
        try captureAllShippedGameModes()
    }

    private func captureAllShippedGameModes() throws {
        let rootDirectory = try GameModeScreenshotWriter.outputDirectory()
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        var captures: [(mode: GameModeScreenshotTarget, variant: GameModeScreenshotVariant, path: URL)] = []
        let textSizeGroups: [(usesAccessibilityTextSize: Bool, variants: [GameModeScreenshotVariant])] = [
            (false, [.portrait, .landscape]),
            (true, [.massiveTextPortrait, .massiveTextLandscape]),
        ]

        for group in textSizeGroups {
            var app = launchForGameModeScreenshots(usesAccessibilityTextSize: group.usesAccessibilityTextSize)

            for mode in GameModeScreenshotTarget.allCases {
                XCTContext.runActivity(named: "Capture \(mode.displayName)") { _ in
                    startGameModeMatch(mode, in: app)

                    for variant in group.variants {
                        applyScreenshotOrientation(variant, app: app)
                        if let path = try? captureGameModeScreenshot(
                            mode: mode,
                            variant: variant,
                            rootDirectory: rootDirectory
                        ) {
                            captures.append((mode, variant, path))
                        }
                    }

                    abandonMatchForScreenshots(in: app)
                    resetSimulatorOrientationToPortrait()
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))

                    if !app.buttons["select_Alice"].waitForExistence(timeout: 5) {
                        app.terminate()
                        app = launchForGameModeScreenshots(usesAccessibilityTextSize: group.usesAccessibilityTextSize)
                    }
                }
            }

            app.terminate()
        }

        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "unknown"
        try GameModeScreenshotWriter.writeManifest(
            to: rootDirectory,
            captures: captures,
            simulatorName: simulatorName
        )

        let expectedCount = GameModeScreenshotTarget.allCases.count * GameModeScreenshotVariant.allCases.count
        XCTAssertEqual(
            captures.count,
            expectedCount,
            "Expected \(expectedCount) screenshots; wrote \(captures.count) to \(rootDirectory.path)"
        )
    }
}

// Per-mode entry points for targeted reruns, e.g.
// `-only-testing:.../testCaptureMickeyMouseScreenshots`
extension GameModeScreenshotUITests {
    func testCaptureX01Screenshots() throws { try captureMode(.x01) }
    func testCaptureCricketScreenshots() throws { try captureMode(.cricket) }
    func testCaptureAmericanCricketScreenshots() throws { try captureMode(.americanCricket) }
    func testCaptureBaseballScreenshots() throws { try captureMode(.baseball) }
    func testCaptureKillerScreenshots() throws { try captureMode(.killer) }
    func testCaptureShanghaiScreenshots() throws { try captureMode(.shanghai) }
    func testCaptureMickeyMouseScreenshots() throws { try captureMode(.mickeyMouse) }
    func testCaptureMulliganScreenshots() throws { try captureMode(.mulligan) }
    func testCaptureEnglishCricketScreenshots() throws { try captureMode(.englishCricket) }
    func testCaptureKnockoutScreenshots() throws { try captureMode(.knockout) }
    func testCaptureSuddenDeathScreenshots() throws { try captureMode(.suddenDeath) }
    func testCaptureFiftyOneByFivesScreenshots() throws { try captureMode(.fiftyOneByFives) }
    func testCaptureGolfScreenshots() throws { try captureMode(.golf) }
    func testCaptureFootballScreenshots() throws { try captureMode(.football) }
    func testCaptureGrandNationalScreenshots() throws { try captureMode(.grandNational) }
    func testCaptureHareAndHoundsScreenshots() throws { try captureMode(.hareAndHounds) }
    func testCaptureFleetScreenshots() throws { try captureMode(.fleet) }
    func testCaptureRaidScreenshots() throws { try captureMode(.raid) }
    func testCaptureAroundTheClockScreenshots() throws { try captureMode(.aroundTheClock) }
    func testCaptureAroundTheClock180Screenshots() throws { try captureMode(.aroundTheClock180) }
    func testCaptureChaseTheDragonScreenshots() throws { try captureMode(.chaseTheDragon) }
    func testCaptureNineLivesScreenshots() throws { try captureMode(.nineLives) }

    private func captureMode(_ mode: GameModeScreenshotTarget) throws {
        let rootDirectory = try GameModeScreenshotWriter.outputDirectory()
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        var captures: [(mode: GameModeScreenshotTarget, variant: GameModeScreenshotVariant, path: URL)] = []
        for usesAccessibilityTextSize in [false, true] {
            let app = launchForGameModeScreenshots(usesAccessibilityTextSize: usesAccessibilityTextSize)
            startGameModeMatch(mode, in: app)
            let variants: [GameModeScreenshotVariant] = usesAccessibilityTextSize
                ? [.massiveTextPortrait, .massiveTextLandscape]
                : [.portrait, .landscape]
            for variant in variants {
                applyScreenshotOrientation(variant, app: app)
                let path = try captureGameModeScreenshot(mode: mode, variant: variant, rootDirectory: rootDirectory)
                captures.append((mode, variant, path))
            }
            app.terminate()
        }

        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "unknown"
        try GameModeScreenshotWriter.writeManifest(
            to: rootDirectory,
            captures: captures,
            simulatorName: simulatorName
        )
        XCTAssertEqual(captures.count, 4)
    }
}
