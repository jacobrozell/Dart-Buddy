import Foundation

public enum CodablePayloadCoder {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    public static func encode<T: Encodable>(_ payload: T) throws -> Data {
        do {
            return try encoder.encode(payload)
        } catch {
            throw AppError(
                code: .serializationFailed,
                layer: .data,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.payload.encode",
                underlyingError: error
            )
        }
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw AppError(
                code: .serializationFailed,
                layer: .data,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.payload.decode",
                underlyingError: error
            )
        }
    }
}
