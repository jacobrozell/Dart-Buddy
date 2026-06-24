import SwiftUI

/// Shared layout and shape tokens for X01 and Cricket scoring pads.
enum ScoringPadStyle {
    static let compactSpacing: CGFloat = 6
    static let accessibilitySpacing: CGFloat = 8

    /// Square keys for uniform scoreboard pads (no pill clipping).
    static var keyShape: Rectangle { Rectangle() }

    static var visitSlotShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xs)
    }

    static var visitSlotStroke: Color {
        Brand.textSecondary.opacity(0.35)
    }
}

extension View {
    /// Empty and filled dart visit slots on scoring pads and score cards.
    func scoringPadVisitSlotStyle(minHeight: CGFloat? = nil, minWidth: CGFloat? = nil) -> some View {
        frame(
            minWidth: minWidth,
            maxWidth: minWidth == nil ? .infinity : minWidth,
            minHeight: minHeight,
            maxHeight: minHeight
        )
        .background(Brand.dartBox, in: ScoringPadStyle.visitSlotShape)
        .overlay {
            ScoringPadStyle.visitSlotShape
                .stroke(ScoringPadStyle.visitSlotStroke, lineWidth: 1)
        }
    }
}

struct ScoringPadKey: View {
    let title: String
    var background: Color = Brand.key
    var foreground: Color = Brand.textPrimary
    var font: Font = .body.weight(.semibold)
    let minHeight: CGFloat
    let accessibilityLabel: String
    var accessibilityHint: String?
    var isSelected: Bool = false
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 44, maxWidth: .infinity, minHeight: minHeight)
                .background(background, in: ScoringPadStyle.keyShape)
        }
        .accessibilityLabel(accessibilityLabel)
        .modifier(OptionalAccessibilityHint(hint: accessibilityHint))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

struct ScoringPadIconKey: View {
    let systemImage: String
    var background: Color = Brand.red
    let minHeight: CGFloat
    let accessibilityLabel: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .frame(minWidth: 44, maxWidth: .infinity, minHeight: minHeight)
                .background(background, in: ScoringPadStyle.keyShape)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
