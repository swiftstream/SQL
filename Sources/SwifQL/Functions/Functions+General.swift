//
//  Functions+General.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let subStr: Self = .init("substr")
    @available(*, deprecated, renamed: "subStr")
    public static var substr: Self { .subStr }
    public static let coalesce: Self = .init("coalesce")
    public static let octetLength: Self = .init("octet_length")
    @available(*, deprecated, renamed: "octetLength")
    public static var octet_length: Self { .octetLength }
    public static let cast: Self = .init("cast")
    public static let nextVal: Self = .init("nextval")
    public static let currVal: Self = .init("currval")
    public static let ifNull: Self = .init("ifnull")
    @available(*, deprecated, renamed: "ifNull")
    public static var ifnull: Self { .ifNull }
    public static let isNull: Self = .init("isnull")
    @available(*, deprecated, renamed: "isNull")
    public static var isnull: Self { .isNull }
    public static let nvl: Self = .init("nvl")
    public static let groupingId: Self = .init("grouping_id")
    public static let expression: Self = .init("expression")
}

extension Fn {
    public static func subStr(_ queryPart: SQLable, _ to: Int) -> SQLable {
        var parts: [SQLPart] = queryPart.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: to)
        return build(.subStr, body: parts)
    }

    @available(*, deprecated, renamed: "subStr(_:_:)")
    public static func substr(_ queryPart: SQLable, _ to: Int) -> SQLable {
        subStr(queryPart, to)
    }
    
    /// `SELECT COALESCE (NULL, 2 , 1);` will return 2
    public static func coalesce(_ queryPart: SQLable...) -> SQLable {
        coalesce(queryPart)
    }
    
    /// `SELECT COALESCE (NULL, 2 , 1);` will return 2
    public static func coalesce(_ queryParts: [SQLable]) -> SQLable {
        var parts: [SQLPart] = []
        for (i, q) in queryParts.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
            }
            parts.append(contentsOf: q.parts)
        }
        return build(.coalesce, body: parts)
    }

    /// Returns the count of all rows in the current aggregate input.
    public static func count() -> SQLable {
        build(.count, body: [])
    }

    /// Returns DuckDB's grouping bitfield for one or more grouping expressions.
    public static func groupingId(
        _ expression: SQLable,
        _ expressions: SQLable...
    ) -> SQLable {
        groupingId([expression] + expressions)
    }

    public static func groupingId(_ expressions: [SQLable]) -> SQLable {
        var parts: [SQLPart] = []
        for (index, expression) in expressions.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: expression.parts)
        }
        return build(.groupingId, body: parts)
    }
    
    public static func octetLength(_ string: SQLable) -> SQLable {
        build(.octetLength, body: string.parts)
    }

    @available(*, deprecated, renamed: "octetLength(_:)")
    public static func octet_length(_ string: SQLable) -> SQLable {
        octetLength(string)
    }
    
    public static func cast(_ queryPart: SQLable, _ to: Type) -> SQLable {
        cast(nil, queryPart, to)
    }
    
    public static func cast(_ from: Type?, _ queryPart: SQLable, _ to: Type) -> SQLable {
        var parts: [SQLPart] = []
        if let from {
            parts.append(SQLPartType(from))
            parts.append(o: .space)
        }
        parts.append(contentsOf: queryPart.parts)
        parts.append(o: .space)
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(SQLPartType(to))
        return build(.cast, body: parts)
    }

    public static func nextVal(_ sequence: SQLable) -> SQLable {
        build(.nextVal, body: sequence.parts)
    }

    public static func currVal(_ sequence: SQLable) -> SQLable {
        build(.currVal, body: sequence.parts)
    }
    
    public static func ifNull(_ value1: SQLable, _ value2: SQLable) -> SQLable {
        var parts: [SQLPart] = value1.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: value2.parts)
        return build(.ifNull, body: parts)
    }
    
    public static func isNull(_ value1: SQLable, _ value2: SQLable) -> SQLable {
        var parts: [SQLPart] = value1.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: value2.parts)
        return build(.isNull, body: parts)
    }
    
    public static func nvl(_ value1: SQLable, _ value2: SQLable) -> SQLable {
        var parts: [SQLPart] = value1.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: value2.parts)
        return build(.nvl, body: parts)
    }
}
