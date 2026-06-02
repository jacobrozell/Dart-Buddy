import Foundation

public protocol FeatureFlagsProvider: Sendable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}
