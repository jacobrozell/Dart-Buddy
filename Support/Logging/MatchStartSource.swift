import Foundation

/// How the user entered or restarted match play for product-health funnels.
enum MatchStartSource: String, Sendable {
    case setup
    case rematch
    case resume
    case deepLink
    case intent
}
