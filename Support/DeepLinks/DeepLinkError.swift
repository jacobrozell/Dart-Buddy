import Foundation

enum DeepLinkError: Error, Equatable {
    case unsupportedScheme
    case unsupportedVersion(String)
    case malformedPath
    case invalidUUID
    case unknownPath
}
