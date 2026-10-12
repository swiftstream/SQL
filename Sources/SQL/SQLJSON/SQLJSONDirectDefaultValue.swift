//
//  SQLJSONDirectDefaultValue.swift
//  SQL
//

import Foundation

/// Role-specific parser-constant representation for a direct runtime SQL/JSON
/// `DEFAULT` value. Categories outside the admitted set return `nil`, so those
/// values stay ordinary binds and fail closed in the target database instead of
/// being guessed into a literal form.
///
/// These encoders never inspect `sql_mode`, string-literal settings, or live
/// connection/session state, and they are not used for the path grammar role.
enum SQLJSONDirectDefaultValue {
    /// PostgreSQL escape-string form for the direct runtime DEFAULT role.
    static func postgresLiteral(_ value: Encodable) -> String? {
        switch category(of: value) {
        case .string(let text): return "E'\(postgresEscapeStringPayload(text))'"
        case .integer(let text): return text
        case nil: return nil
        }
    }

    /// MySQL introduced UTF-8 hex form for the `JSON_VALUE` DEFAULT role only.
    /// No byte of the input string is emitted as SQL text.
    static func mysqlJSONValueLiteral(_ value: Encodable) -> String? {
        switch category(of: value) {
        case .string(let text): return "_utf8mb4 X'\(uppercaseHex(text))'"
        case .integer(let text): return text
        case nil: return nil
        }
    }

    private enum Category {
        case string(String)
        case integer(String)
    }

    /// Unadmitted categories are matched first so a bridged numeric conversion
    /// cannot reclassify them into an admitted family.
    private static func category(of value: Encodable) -> Category? {
        switch value {
        case is Bool, is Float, is Double, is Decimal, is UUID, is Data,
             is PureDate, is PureTime, is DateTime, is Interval:
            nil
        case let text as String:
            .string(text)
        case let number as Int:
            .integer(String(describing: number))
        case let number as Int8:
            .integer(String(describing: number))
        case let number as Int16:
            .integer(String(describing: number))
        case let number as Int32:
            .integer(String(describing: number))
        case let number as Int64:
            .integer(String(describing: number))
        case let number as UInt:
            .integer(String(describing: number))
        case let number as UInt8:
            .integer(String(describing: number))
        case let number as UInt16:
            .integer(String(describing: number))
        case let number as UInt32:
            .integer(String(describing: number))
        case let number as UInt64:
            .integer(String(describing: number))
        default:
            nil
        }
    }

    private static func postgresEscapeStringPayload(_ text: String) -> String {
        var payload = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\u{5C}":
                payload += "\u{5C}\u{5C}"
            case "\u{27}":
                payload += "\u{27}\u{27}"
            default:
                payload.unicodeScalars.append(scalar)
            }
        }
        return payload
    }

    private static func uppercaseHex(_ text: String) -> String {
        let digits = Array("0123456789ABCDEF")
        var hex = ""
        for byte in text.utf8 {
            hex.append(digits[Int(byte >> 4)])
            hex.append(digits[Int(byte & 0x0F)])
        }
        return hex
    }
}
