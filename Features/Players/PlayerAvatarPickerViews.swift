import SwiftUI

struct AvatarStylePicker: View {
    @Binding var selection: PlayerAvatarStyle

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.s2) {
            ForEach(PlayerAvatarStyle.allCases) { style in
                let isSelected = selection == style
                Button {
                    selection = style
                } label: {
                    Image(systemName: style.symbolName)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Brand.textPrimary : Brand.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, DS.Spacing.s3)
                        .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .strokeBorder(Brand.green, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.displayName)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

struct PlayerColorTokenPicker: View {
    @Binding var selection: PlayerColorToken

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: DS.Spacing.s2) {
            ForEach(PlayerColorToken.allCases) { token in
                let isSelected = selection == token
                Button {
                    selection = token
                } label: {
                    Circle()
                        .fill(PlayerVisualViews.color(for: token))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Brand.textOnAccent)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(token.displayName)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
