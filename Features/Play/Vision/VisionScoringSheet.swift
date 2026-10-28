import SwiftUI

/// Camera scoring sheet (Phase A, assistive): the player taps the outer double wire
/// at 20, 6, 3, and 11 to lock a homography, then confirms detection proposals.
/// The number pad stays available behind the sheet for manual corrections.
struct VisionScoringSheet: View {
    let logger: (any AppLogger)?
    /// Whether the match can accept another dart right now (human turn, visit not full).
    let isInputAllowed: Bool
    let onDartConfirmed: (DartInput, VisionThrowMetadata) -> Void

    @StateObject private var viewModel: VisionScoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCorrecting = false
    @State private var correctionDarts: [DartInput] = []
    @State private var correctionMultiplier: DartMultiplier = .single

    init(
        logger: (any AppLogger)?,
        isInputAllowed: Bool,
        onDartConfirmed: @escaping (DartInput, VisionThrowMetadata) -> Void
    ) {
        self.logger = logger
        self.isInputAllowed = isInputAllowed
        self.onDartConfirmed = onDartConfirmed
        _viewModel = StateObject(wrappedValue: VisionScoringViewModel(logger: logger))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                CameraPreviewView(
                    session: viewModel.camera.captureSession,
                    overlay: nil,
                    calibrationTaps: viewModel.calibrationTaps,
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
                    hintsOverlay
                }
                .padding(DS.Spacing.s3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            proposalBar
        }
        .background(Brand.background.ignoresSafeArea())
        .task {
            viewModel.onDartConfirmed = onDartConfirmed
            await viewModel.start()
        }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.proposal?.id) { _, _ in
            isCorrecting = false
            correctionDarts = []
            correctionMultiplier = .single
        }
    }

    private var header: some View {
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
            statusPill(
                viewModel.calibrationTaps.count == BoardCalibration.outerWireCalibrationSegments.count
                    ? L10n.string("vision.calibration.waitingForImage")
                    : L10n.format("vision.calibration.tapOuterWireFormat", viewModel.nextCalibrationSegment)
            )
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
    private var proposalBar: some View {
        VStack(spacing: DS.Spacing.s2) {
            if let proposal = viewModel.proposal {
                proposalContent(proposal)
            } else {
                Text(L10n.string("vision.proposal.waiting"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
            tallyLine
        }
        .padding(DS.Spacing.s3)
        .background(Brand.background)
    }

    @ViewBuilder
    private func proposalContent(_ proposal: DetectedThrow) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("vision.proposal.title"))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    Text(proposal.dart.compactDisplayLabel)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                        .accessibilityLabel(proposal.dart.spokenAccessibilityName)
                }
                Spacer()
                Text(L10n.format(
                    "vision.proposal.confidenceFormat",
                    Int((proposal.visionConfidence * 100).rounded())
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            }
            if isCorrecting {
                DartNumberPad(
                    enteredDarts: $correctionDarts,
                    selectedMultiplier: $correctionMultiplier,
                    maxDarts: 1,
                    showsVisitPreview: false,
                    onUndoTurn: { isCorrecting = false }
                )
            }
            HStack(spacing: DS.Spacing.s2) {
                proposalButton(L10n.string("vision.proposal.reject"), fill: Brand.card, ink: Brand.textPrimary) {
                    viewModel.rejectProposal()
                }
                proposalButton(L10n.string("vision.proposal.change"), fill: Brand.card, ink: Brand.textPrimary) {
                    isCorrecting = true
                }
                proposalButton(confirmTitle(for: proposal), fill: Brand.green, ink: .black) {
                    viewModel.confirmProposal(corrected: correctionDarts.first)
                }
                .disabled(!isInputAllowed || (isCorrecting && correctionDarts.isEmpty))
                .opacity(isInputAllowed && !(isCorrecting && correctionDarts.isEmpty) ? 1 : 0.45)
            }
            if !isInputAllowed {
                Text(L10n.string("vision.proposal.inputBlocked"))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func confirmTitle(for proposal: DetectedThrow) -> String {
        guard let corrected = correctionDarts.first, corrected != proposal.dart else {
            return L10n.string("vision.proposal.confirm")
        }
        return L10n.format("vision.proposal.addCorrectedFormat", corrected.compactDisplayLabel)
    }

    private func proposalButton(
        _ title: String,
        fill: Color,
        ink: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s3)
                .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .foregroundStyle(ink)
        }
    }

    @ViewBuilder
    private var tallyLine: some View {
        let tally = viewModel.tally
        if tally.scored > 0 || tally.dismissed > 0 {
            Text(tally.scored > 0
                ? L10n.format(
                    "vision.tally.summaryFormat",
                    tally.exact,
                    tally.scored,
                    tally.changed,
                    tally.dismissed
                )
                : L10n.format("vision.tally.dismissedOnlyFormat", tally.dismissed)
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("vision_detection_tally")
        }
    }
}
