import Foundation

public enum DartMultiplier: String, Codable, Sendable {
    case single
    case double
    case triple

    public var markValue: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }
}

public enum DartSegment: Codable, Equatable, Hashable, Sendable {
    case oneToTwenty(Int)
    case outerBull
    case innerBull
    case miss

    public var baseValue: Int {
        switch self {
        case let .oneToTwenty(value):
            return value
        case .outerBull:
            return 25
        case .innerBull:
            return 25
        case .miss:
            return 0
        }
    }

    public var cricketTargetRaw: String? {
        switch self {
        case let .oneToTwenty(value) where (15 ... 20).contains(value):
            return String(value)
        case .outerBull, .innerBull:
            return "bull"
        default:
            return nil
        }
    }
}

public struct DartInput: Codable, Equatable, Hashable, Sendable {
    public let multiplier: DartMultiplier
    public let segment: DartSegment
    public let isMiss: Bool

    public init(multiplier: DartMultiplier, segment: DartSegment, isMiss: Bool = false) {
        self.multiplier = multiplier
        self.segment = segment
        self.isMiss = isMiss
    }

    public var points: Int {
        guard !isMiss else { return 0 }
        switch segment {
        case .innerBull:
            return 50
        case .outerBull:
            return 25
        case .miss:
            return 0
        case .oneToTwenty:
            return segment.baseValue * multiplier.markValue
        }
    }

    /// VoiceOver-friendly dart name (e.g. `Triple 20`, `Outer Bull`, `Miss`).
    public var spokenAccessibilityName: String {
        if isMiss { return L10n.string("scoring.segment.miss.accessibility") }
        switch segment {
        case .innerBull:
            return L10n.string("scoring.segment.innerBull.accessibility")
        case .outerBull:
            return L10n.string("scoring.segment.outerBull.accessibility")
        case .miss:
            return L10n.string("scoring.segment.miss.accessibility")
        case let .oneToTwenty(value):
            switch multiplier {
            case .single:
                return L10n.format("scoring.dart.single.accessibility", value)
            case .double:
                return L10n.format("scoring.dart.double.accessibility", value)
            case .triple:
                return L10n.format("scoring.dart.triple.accessibility", value)
            }
        }
    }

    /// Label for a number-pad key before the dart is entered (`armedMultiplier` is DOUBLE/TRIPLE selection).
    public static func padKeyAccessibilityLabel(segmentValue: Int, armedMultiplier: DartMultiplier) -> String {
        if segmentValue == 0 {
            return L10n.string("scoring.segment.miss.accessibility")
        }
        if segmentValue == 25 {
            if armedMultiplier == .double {
                return L10n.string("scoring.dart.doubleBull.accessibility")
            }
            return L10n.string("scoring.segment.outerBull.accessibility")
        }
        switch armedMultiplier {
        case .single:
            return L10n.format("scoring.dart.single.accessibility", segmentValue)
        case .double:
            return L10n.format("scoring.dart.double.accessibility", segmentValue)
        case .triple:
            return L10n.format("scoring.dart.triple.accessibility", segmentValue)
        }
    }
}
