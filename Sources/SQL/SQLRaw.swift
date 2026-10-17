//
//  SQLRaw.swift
//  SQL
//

public struct SQLRaw: SQLable, ExpressibleByStringInterpolation {
    public typealias StringLiteralType = String

    private let storage: [SQLPart]

    public var parts: [SQLPart] {
        storage
    }

    public init(stringLiteral value: String) {
        storage = [SQLPartOperator(value)]
    }

    public init(stringInterpolation: StringInterpolation) {
        storage = stringInterpolation.parts
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var parts: [SQLPart] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            parts.reserveCapacity(literalCapacity + interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            guard !literal.isEmpty else { return }
            parts.append(SQLPartOperator(literal))
        }

        public mutating func appendInterpolation<T: Encodable>(bind value: T) {
            parts.append(SQLPartUnsafeValue(value))
        }

        public mutating func appendInterpolation<T: Encodable>(bind value: T?) {
            parts.append(SQLPartUnsafeValue(value))
        }
    }
}
