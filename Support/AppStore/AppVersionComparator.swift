import Foundation

enum AppVersionComparator {
    static func isStoreVersionNewer(store: String, than installed: String) -> Bool {
        compare(store, installed) == .orderedDescending
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(lhs)
        let right = components(rhs)
        let count = max(left.count, right.count)
        for index in 0 ..< count {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue > rightValue { return .orderedDescending }
            if leftValue < rightValue { return .orderedAscending }
        }
        return .orderedSame
    }

    static func components(_ version: String) -> [Int] {
        version.split(separator: ".", omittingEmptySubsequences: false).map { segment in
            let digits = segment.prefix { $0.isNumber }
            return Int(digits) ?? 0
        }
    }
}
