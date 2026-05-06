import Foundation

public enum SchemaInvariantValidator {
    public static func hasContiguousEventIndexes(_ indexes: [Int]) -> Bool {
        let sorted = indexes.sorted()
        guard let first = sorted.first else {
            return true
        }
        for (offset, value) in sorted.enumerated() where value != first + offset {
            return false
        }
        return true
    }
}
