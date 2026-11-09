import SwiftUI

/// Camera scoring sheet: finds the board, then scores darts automatically as they
/// land. The current visit is shown underneath so any dart can be corrected with a
/// tap; the match screen stays visible behind the half-height sheet.
struct VisionScoringSheet: View {
    /// Whether the match can accept another dart right now (human turn, visit not full).
    let isInputAllowed: Bool
    /// Darts entered in the current visit (from the match, the source of truth).
    let visitDarts: [DartInput]
    /// Whether the visit can be submitted right now (human turn with at least one dart).
    let canSubmitVisit: Bool
    let actions: Actions

    /// How the sheet talks to the match. The match engine stays the source of truth.
    struct Actions {
        /// Offers a detected dart to the match; returns whether it was accepted.
        let onDartDetected: (DartInput, VisionThrowMetadata) -> Bool
        let onBoardCleared: () -> Void
        let onCorrectDart: (Int, DartInput) -> Void
        let onUndoLastDart: () -> Void
        let onAddMiss: () -> Void
        let onSubmitVisit: () -> Void
    }

    @StateObject private var viewModel: VisionScoringViewModel
    @State private var editingIndex: Int?
    @State private var editMultiplier: DartMultiplier = .single
    @Environment(\.dismiss) private var dismiss

    init(
        logger: (any AppLogger)?,
        isInputAllowed: Bool,
        visitDarts: [DartInput],
        canSubmitVisit: Bool,
        actions: Actions
    ) {
        self.isInputAllowed = isInputAllowed
        self.visitDarts = visitDarts
        self.canSubmitVisit = canSubmitVisit
        self.actions = actions
        _viewModel = StateObject(wrappedValue: VisionScoringViewModel(logger: logger))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                CameraPreviewView(session: viewModel.camera.captureSession) { angle in
                    viewModel.setVideoRotationAngle(angle)
                }
                .accessibilityHidden(true)
                if let overlay = viewModel.boardOverlay {
                    BoardOverlayView(
                        overlay: overlay,
                        lastTip: viewModel.lastTip,
                        isAdjusting: viewModel.status == .adjusting,
                        onMoveLandmark: { index, point in viewModel.moveLandmark(index, to: point) }
                    )
                }
                VStack(spacing: DS.Spacing.s2) {
                    statusOverlay
                    Spacer()
                    hintsOverlay
                }
                .padding(DS.Spacing.s3)
                // Status pills must not swallow drags meant for the calibration handles.
                .allowsHitTesting(viewModel.status != .adjusting)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .clipped()
            bottomBar
        }
        .background(Brand.background.ignoresSafeArea())
        .task {
            viewModel.onDartDetected = actions.onDartDetected
            viewModel.onBoardCleared = actions.onBoardCleared
            await viewModel.start()
        }
        .onDisappear { viewModel.stop() }
        .onChange(of: visitDarts.count) { _, count in
            viewModel.syncVisit(dartCount: count)
            if let editingIndex, editingIndex >= count {
                self.editingIndex = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: DS.Spacing.s3) {
            Text(L10n.string("vision.title"))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Spacer()
            if viewModel.status == .adjusting {
                Button {
                    viewModel.rotateNumbering(clockwise: false)
                } label: {
                    Image(systemName: "rotate.left")
                }
                .accessibilityLabel(L10n.string("vision.action.rotateLeft"))
                Button {
                    viewModel.rotateNumbering(clockwise: true)
                } label: {
                    Image(systemName: "rotate.right")
                }
                .accessibilityLabel(L10n.string("vision.action.rotateRight"))
                Button(L10n.string("vision.action.done")) {
                    viewModel.finishAdjusting()
                }
                .accessibilityIdentifier("vision_adjust_done_button")
            } else {
                Button(L10n.string("vision.action.adjust")) {
                    viewModel.beginAdjusting()
                }
                .accessibilityIdentifier("vision_adjust_button")
                Button(L10n.string("vision.action.recalibrate")) {
                    viewModel.recalibrate()
                }
                .accessibilityIdentifier("vision_recalibrate_button")
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
            }
            .accessibilityLabel(L10n.string("common.close"))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Brand.green)
        .padding(DS.Spacing.s3)
    }

    // MARK: - Camera overlays

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
        case .adjusting:
            statusPill(L10n.string("vision.status.adjusting"))
        case .arming:
            statusPill(L10n.string("vision.status.arming"), showsProgress: true)
        case .ready:
            statusPill(L10n.string("vision.status.ready"))
        case .paused(.calibrationDrift):
            VStack(spacing: DS.Spacing.s2) {
                statusPill(L10n.string("vision.status.drift"))
                HStack(spacing: DS.Spacing.s2) {
                    overlayButton(L10n.string("vision.action.keepCalibration")) {
                        viewModel.resumeAfterDrift()
                    }
                    overlayButton(L10n.string("vision.action.recalibrate")) {
                        viewModel.recalibrate()
                    }
                }
            }
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
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DS.Spacing.s2)
        .padding(.horizontal, DS.Spacing.s4)
        .background(.black.opacity(0.6), in: Capsule())
    }

    private func overlayButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.vertical, DS.Spacing.s2)
                .padding(.horizontal, DS.Spacing.s3)
                .background(Brand.green, in: Capsule())
        }
    }

    @ViewBuilder
    private var hintsOverlay: some View {
        if let hint = viewModel.hints.first {
            Text(L10n.string(hint.localizationKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, DS.Spacing.s2)
                .padding(.horizontal, DS.Spacing.s4)
                .background(.black.opacity(0.6), in: Capsule())
        }
    }

    // MARK: - Visit bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: DS.Spacing.s2) {
            if let editingIndex, visitDarts.indices.contains(editingIndex) {
                dartEditor(index: editingIndex)
            } else {
                visitRow
                if canSubmitVisit {
                    Button {
                        actions.onSubmitVisit()
                    } label: {
                        Text(L10n.string("vision.visit.submit"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s2)
                            .background(Brand.green, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                            .foregroundStyle(.black)
                    }
                    .accessibilityIdentifier("vision_submit_visit_button")
                }
                Text(visitCaption)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Spacing.s3)
        .frame(maxWidth: .infinity)
        .background(Brand.background)
    }

    private var visitCaption: String {
        if viewModel.lastDetectionWasIgnored || !isInputAllowed {
            return L10n.string("vision.visit.inputBlocked")
        }
        if visitDarts.isEmpty {
            return L10n.string("vision.visit.empty")
        }
        if viewModel.boardClearedSinceLastDart {
            return L10n.string("vision.visit.pulledEarly")
        }
        return L10n.string("vision.visit.tapToFix")
    }

    private var visitRow: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(0 ..< 3, id: \.self) { index in
                visitSlot(index: index)
            }
            Button {
                actions.onAddMiss()
            } label: {
                Text(L10n.string("vision.visit.addMiss"))
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, DS.Spacing.s3)
                    .padding(.horizontal, DS.Spacing.s3)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                    .foregroundStyle(Brand.textPrimary)
            }
            .disabled(!isInputAllowed)
            .opacity(isInputAllowed ? 1 : 0.45)
            .accessibilityIdentifier("vision_add_miss_button")
            Button {
                actions.onUndoLastDart()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.headline)
                    .padding(DS.Spacing.s3)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                    .foregroundStyle(Brand.textPrimary)
            }
            .accessibilityLabel(L10n.string("vision.visit.undo"))
            .accessibilityIdentifier("vision_undo_button")
        }
    }

    @ViewBuilder
    private func visitSlot(index: Int) -> some View {
        if visitDarts.indices.contains(index) {
            let dart = visitDarts[index]
            let flagged = viewModel.needsReview(visitIndex: index, dart: dart)
            Button {
                editMultiplier = dart.isMiss ? .single : dart.multiplier
                editingIndex = index
            } label: {
                Text(dart.compactDisplayLabel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s3)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(flagged ? Color.orange : Color.clear, lineWidth: 2)
                    )
            }
            .accessibilityLabel(dart.spokenAccessibilityName)
            .accessibilityValue(flagged ? L10n.string("vision.visit.review") : "")
            .accessibilityHint(L10n.string("vision.visit.tapToFix"))
        } else {
            Text("–")
                .font(.title3.weight(.bold))
                .foregroundStyle(Brand.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s3)
                .background(Brand.card.opacity(0.5), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityHidden(true)
        }
    }

    // MARK: - Correction editor

    private func dartEditor(index: Int) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            HStack {
                Text(L10n.format("vision.edit.titleFormat", index + 1))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Button(L10n.string("common.cancel")) {
                    editingIndex = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.green)
            }
            Picker(L10n.string("scoring.multiplier.hint"), selection: $editMultiplier) {
                Text(L10n.string("scoring.multiplier.single.accessibility")).tag(DartMultiplier.single)
                Text(L10n.string("scoring.multiplier.double.accessibility")).tag(DartMultiplier.double)
                Text(L10n.string("scoring.multiplier.triple.accessibility")).tag(DartMultiplier.triple)
            }
            .pickerStyle(.segmented)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(1 ... 20, id: \.self) { value in
                    editorKey("\(value)") {
                        commitEdit(index: index, dart: DartInput(multiplier: editMultiplier, segment: .oneToTwenty(value)))
                    }
                }
                editorKey("25") {
                    commitEdit(index: index, dart: DartInput(multiplier: .single, segment: .outerBull))
                }
                editorKey("50") {
                    commitEdit(index: index, dart: DartInput(multiplier: .single, segment: .innerBull))
                }
                editorKey(L10n.string("scoring.pad.missLabel")) {
                    commitEdit(index: index, dart: DartInput(multiplier: .single, segment: .miss, isMiss: true))
                }
            }
        }
    }

    private func editorKey(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s2)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .foregroundStyle(Brand.textPrimary)
        }
    }

    private func commitEdit(index: Int, dart: DartInput) {
        actions.onCorrectDart(index, dart)
        editingIndex = nil
    }
}
