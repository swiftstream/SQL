//
//  SQLable+Types.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

extension Optional: SQLable, CustomStringConvertible where Wrapped: SQLable {
    public var parts: [SQLPart] {
        switch self {
        case .none:
            return [SQLPartSafeValue(nil)]
        case .some(let value):
            return value.parts
        }
    }
}
extension Optional: RowField where Wrapped: SQLable {}
extension String: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UUID: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Decimal: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Double: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Float: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UInt: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UInt8: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UInt16: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UInt32: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension UInt64: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Int: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Int8: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Int16: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Int32: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Int64: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Date: SQLable {
    public var parts: [SQLPart] { [SQLPartDate(self)] }
}
extension PureDate: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension PureTime: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension DateTime: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Interval: SQLable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
extension Data: SQLable {
    public var parts: [SQLPart] {
        return [
            SQLPartOperator("decode"),
            SQLPartOperator.openBracket,
            SQLPartSafeValue(base64EncodedString()),
            SQLPartOperator.comma,
            SQLPartOperator.space,
            SQLPartSafeValue("base64"),
            SQLPartOperator.closeBracket
        ]
    }
}
public protocol SQLRawRepresentable: RawRepresentable, SQLable {}
extension SQLRawRepresentable {
    public var parts: [SQLPart] {
        if let a = self.rawValue as? SQLable {
            return a.parts
        }
        return []
    }
}