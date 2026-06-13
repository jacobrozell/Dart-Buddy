import SwiftUI

/// Camera scoring sheet (Phase A, assistive): guides board calibration, then shows
/// detection proposals the player confirms into the current visit or dismisses.
/// The number pad stays available behind the sheet for manual corrections.
struct VisionScoringSheet: View {
    let logger: (any AppLogger)?
    /// Whether the match can accept another dart right now (human turn, visit not full).
    let isInputAllowed: Bool
    let onDartConfirmed: (DartInput, VisionThrowMetadata) -> Void

    @StateObject private var viewModel: VisionScoringViewModel
    @Environment(\.dismiss) private var dismiss

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
                CameraPreviewView(session: viewModel.camera.captureSession, overlay: viewModel.boardOverlay)
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
    }

    private var header: some View {
        HStack {
            Text(L10n.string("vision.title"))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Spacer()
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
            VStack(spacing: DS.Spacing.s1) {
                statusPill(L10n.string("vision.status.calibrating"), showsProgress: true)
                if viewModel.calibrationProgress > 0 {
                    ProgressView(value: viewModel.calibrationProgress)
                        .tint(Brand.green)
                        .frame(maxWidth: 200)
                        .accessibilityLabel(L10n.string("vision.status.calibrating"))
                }
            }
        case .ready:
            statusPill(
                L10n.format("vision.calibration.qualityFormat", Int((viewModel.fitQuality * 100).rounded()))
            )
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
        if let proposal = viewModel.proposal {
            VStack(spacing: DS.Spacing.s2) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string("vision.proposal.title"))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        Text(proposal.dart.spokenAccessibilityName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                    }
                    Spacer()
                    Text(L10n.format(
                        "vision.proposal.confidenceFormat",
                        Int((proposal.visionConfidence * 100).rounded())
                    ))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                }
                HStack(spacing: DS.Spacing.s2) {
                    Button {
                        viewModel.rejectProposal()
                    } label: {
                        Text(L10n.string("vision.proposal.reject"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s3)
                            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                            .foregroundStyle(Brand.textPrimary)
                    }
                    Button {
                        viewModel.confirmProposal()
                    } label: {
                        Text(L10n.string("vision.proposal.confirm"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s3)
                            .background(Brand.green, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                            .foregroundStyle(.black)
                    }
                    .disabled(!isInputAllowed)
                    .opacity(isInputAllowed ? 1 : 0.45)
                }
                if !isInputAllowed {
                    Text(L10n.string("vision.proposal.inputBlocked"))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            .padding(DS.Spacing.s3)
            .background(Brand.background)
            .accessibilityElement(children: .contain)
        } else {
            Text(L10n.string("vision.proposal.waiting"))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .padding(DS.Spacing.s3)
        }
    }
}
