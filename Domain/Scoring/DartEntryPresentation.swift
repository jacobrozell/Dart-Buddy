import Foundation

/// How the player builds `enteredDarts` during a match — the number pad grid or the
/// tappable visual dartboard. Orthogonal to X01's `ScoringInputMode` (total vs per-dart).
public enum DartEntryPresentation: String, CaseIterable, Codable, Sendable {
    case numberPad
    case visualBoard

    public static let `default`: DartEntryPresentation = .numberPad

    public init(rawValueOrDefault raw: String?) {
        self = raw.flatMap(DartEntryPresentation.init(rawValue:)) ?? .default
    }

    public var toggled: DartEntryPresentation {
        self == .numberPad ? .visualBoard : .numberPad
    }
}
