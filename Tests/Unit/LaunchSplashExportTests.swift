import SwiftUI
import XCTest
@testable import DartBuddy

final class LaunchSplashExportTests: XCTestCase {
    private let exportSize = CGSize(width: 393, height: 852)
    private let exportScale: CGFloat = 3

    @MainActor
    func testExportLaunchSplashAssets() throws {
        let sourceRoot = try sourceRootURL()
        let outputDirectory = sourceRoot
            .appendingPathComponent("Resources/LaunchSplashCandidates", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for scheme in [ColorScheme.light, ColorScheme.dark] {
            let suffix = scheme == .light ? "light" : "dark"
            let backgroundURL = outputDirectory.appendingPathComponent("ambient-\(suffix).png")
            try export(
                LaunchSplashBackgroundCanvas()
                    .frame(width: exportSize.width, height: exportSize.height)
                    .environment(\.colorScheme, scheme),
                to: backgroundURL
            )

            let composedURL = outputDirectory.appendingPathComponent("ambient-\(suffix)-composed.png")
            try export(
                launchSplashPreview(colorScheme: scheme),
                to: composedURL
            )
        }
    }

    @MainActor
    private func launchSplashPreview(colorScheme: ColorScheme) -> some View {
        ZStack {
            LaunchSplashBackgroundCanvas()
            VStack(spacing: DS.Spacing.s3) {
                Spacer()
                LaunchSplashWordmark()
                LaunchSplashExportSpinner()
                    .padding(.bottom, DS.Spacing.s6)
            }
            .padding(.horizontal, DS.Spacing.s4)
        }
        .frame(width: exportSize.width, height: exportSize.height)
        .environment(\.colorScheme, colorScheme)
    }

    @MainActor
    private func export<Content: View>(_ content: Content, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(exportSize)
        renderer.scale = exportScale

        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("Failed to render \(url.lastPathComponent)")
            return
        }

        try data.write(to: url, options: .atomic)
    }

    private func sourceRootURL() throws -> URL {
        if let sourceRoot = ProcessInfo.processInfo.environment["SRCROOT"], !sourceRoot.isEmpty {
            return URL(fileURLWithPath: sourceRoot, isDirectory: true)
        }

        let currentFile = URL(fileURLWithPath: #filePath)
        return currentFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct LaunchSplashExportSpinner: View {
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(Brand.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 22, height: 22)
            .rotationEffect(.degrees(-90))
    }
}
