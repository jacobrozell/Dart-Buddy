import SwiftUI

/// Camera scoring sheet: outer-wire calibration, then a visit tray for hands-free
/// detection with review and submit into the active X01 turn.
struct VisionScoringSheet: View {
    let logger: (any AppLogger)?
    let dartsAllowed: Int
    /// Changes whenever the match moves to a new turn, so a stale tray is dropped.
    let turnKey: String?
    let remainingScore: Int?
    let visitEnds: ([DartInput]) -> Bool
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let onVisitSubmitted: ([DartInput]) -> Void

    @StateObject private var viewModel: VisionScoringViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        logger: (any AppLogger)?,
        dartsAllowed: Int,
        turnKey: String?,
        remainingScore: Int?,
        visitEnds: @escaping ([DartInput]) -> Bool,
        audio: any AudioFeedbackService,
        haptics: any HapticsService,
        onVisitSubmitted: @escaping ([DartInput]) -> Void
    ) {
        self.logger = logger
        self.dartsAllowed = dartsAllowed
        self.turnKey = turnKey
        self.remainingScore = remainingScore
        self.visitEnds = visitEnds
        self.audio = audio
        self.haptics = haptics
        self.onVisitSubmitted = onVisitSubmitted
        _viewModel = StateObject(wrappedValue: VisionScoringViewModel(logger: logger))
    }

    private var dartMarkers: [CameraPreviewView.DartMarker] {
        viewModel.visit.enumerated().compactMap { index, entry in
            guard let detection = entry.detection,
                  let imageX = detection.imageX,
                  let imageY = detection.imageY else { return nil }
            return CameraPreviewView.DartMarker(number: index + 1, imageX: imageX, imageY: imageY)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                CameraPreviewView(
                    session: viewModel.camera.captureSession,
                    overlay: nil,
                    calibrationTaps: viewModel.calibrationTaps,
                    dartMarkers: dartMarkers,
                    aspectRatio: viewModel.previewAspectRatio,
                    onCalibrationTap: { imageX, imageY in
                        viewModel.registerCalibrationTap(imageX: imageX, imageY: imageY)
                    }
                )
                    .ignoresSafeArea(edges: .horizontal)
                    .accessibilityHidden(true)
                VStack {
                    statusOverlay
                    Spacer()
                    calibrationGuide
                    hintsOverlay
                }
                .padding(DS.Spacing.s3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            visitBar
        }
        .background(Brand.background.ignoresSafeArea())
        .task {
            viewModel.visitEnds = visitEnds
            viewModel.onVisitSubmitted = onVisitSubmitted
            viewModel.onDartDetected = { dart in
                if dart.isMiss { audio.playMiss() } else { audio.playHit() }
                haptics.playImpact()
            }
            viewModel.updateTurn(dartsAllowed: dartsAllowed, turnKey: turnKey)
            await viewModel.start()
        }
        .onChange(of: dartsAllowed) { _, new in
            viewModel.updateTurn(dartsAllowed: new, turnKey: turnKey)
        }
        .onChange(of: turnKey) { _, new in
            viewModel.updateTurn(dartsAllowed: dartsAllowed, turnKey: new)
        }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        VStack(spacing: DS.Spacing.s1) {
            HStack {
                Text(L10n.string("vision.title"))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                if viewModel.canUndoCalibrationTap {
                    Button(L10n.string("vision.action.undoTap")) {
                        viewModel.undoCalibrationTap()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.green)
                }
                Button(L10n.string("vision.action.recalibrate")) {
                    viewModel.recalibrate()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.green)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                }
                .accessibilityLabel(L10n.string("common.close"))
                .padding(.leading, DS.Spacing.s3)
            }
            if let remainingScore {
                Text(L10n.format("vision.visit.remainingFormat", remainingScore))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(DS.Spacing.s3)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch viewModel.status {
        case .idle, .requestingAccess:
            statusPill(L10n.string("vision.status.requestingAccess"), showsProgress: true)
        case .accessDenied:
            statusPill(L10n.string("vision.status.accessDenied"))
        case .cameraUnavailable:
            statusPill(L10n.string("vision.status.cameraUnavailable"))
        case .calibrating:
            if viewModel.previewAspectRatio <= 0 {
                statusPill(L10n.string("vision.calibration.waitingForImage"))
            } else if viewModel.calibrationRejected {
                statusPill(L10n.string("vision.calibration.pointsRejected"))
            } else {
                statusPill(
                    L10n.format(
                        "vision.calibration.tapCrossingFormat",
                        viewModel.nextCalibrationCrossing.left,
                        viewModel.nextCalibrationCrossing.right
                    )
                )
            }
        case .ready:
            statusPill(L10n.string("vision.calibration.locked"))
        case .paused(.calibrationDrift):
            statusPill(L10n.string("vision.status.drift"))
        case .paused(.userPaused):
            statusPill(L10n.string("vision.status.paused"))
        }
    }

    private func statusPill(_ text: String, showsProgress: Bool = false) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            if showsProgress {
                ProgressView().tint(.white)
            }
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, DS.Spacing.s2)
        .padding(.horizontal, DS.Spacing.s4)
        .background(.black.opacity(0.55), in: Capsule())
    }

    @ViewBuilder
    private var calibrationGuide: some View {
        let taps = viewModel.calibrationTaps.count
        if viewModel.status == .calibrating, taps < BoardCalibration.outerWireCalibrationCrossings.count {
            HStack(alignment: .bottom, spacing: DS.Spacing.s2) {
                CalibrationTapGuide(completedTaps: taps)
                    .accessibilityHidden(true)
                Text(L10n.string("vision.calibration.guideCaption"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(DS.Spacing.s2)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var hintsOverlay: some View {
        if let hint = viewModel.hints.first {
            Text(L10n.string(hint.localizationKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, DS.Spacing.s2)
                .padding(.horizontal, DS.Spacing.s4)
                .background(.black.opacity(0.55), in: Capsule())
        }
    }

    @ViewBuilder
    private var visitBar: some View {
        VStack(spacing: DS.Spacing.s2) {
            tallyLine
            if viewModel.status == .ready || viewModel.status == .paused(.userPaused) {
                VisionVisitTray(viewModel: viewModel)
            } else if viewModel.status == .paused(.calibrationDrift) {
                Text(L10n.string("vision.status.drift"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .padding(DS.Spacing.s3)
        .background(Brand.background)
    }

    @ViewBuilder
    private var tallyLine: some View {
        let tally = viewModel.tally
        let boardIsLive = viewModel.status == .ready || viewModel.status == .paused(.userPaused)
        let hasActivity = tally.scored > 0 || tally.dismissed > 0 || tally.addedByHand > 0
        if boardIsLive || hasActivity {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.format(
                    "vision.tally.summaryFormat",
                    tally.exact,
                    tally.scored,
                    tally.changed,
                    tally.dismissed
                ))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Brand.textPrimary)
                if tally.addedByHand > 0 {
                    Text(L10n.format("vision.tally.addedFormat", tally.addedByHand))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("vision_detection_tally")
        }
    }
}
