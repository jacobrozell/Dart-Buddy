import SwiftUI

enum GameplayLayout {
    static func contentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }
}
