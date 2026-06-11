import Foundation
import SwiftData

enum SwiftDataStoreReset {
    static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<T>())
        for record in records {
            context.delete(record)
        }
    }

    static func count<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<T>()).count
    }
}
