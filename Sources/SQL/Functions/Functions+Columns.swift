//
//  Functions+Columns.swift
//  SwifQL
//

import Foundation

extension Fn.Name {
    public static let columns: Self = .init("COLUMNS")
    public static let unpack: Self = .init("UNPACK")
}

extension Fn {
    /// Expands the supplied expression through DuckDB's generic COLUMNS form.
    public static func columns(_ expression: SQLable) -> SQLable {
        build(.columns, body: expression.parts)
    }

    /// Selects columns by a native COLUMNS regex value.
    public static func columns(regex: String) -> SQLable {
        build(.columns, body: [SQLPartUnsafeValue(regex)])
    }

    /// Selects structural column names using the exact native COLUMNS list form.
    public static func columns(
        names first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        columns(names: [first] + rest)
    }

    /// Array form for helper-driven structural COLUMNS composition.
    public static func columns(names: [KeyPathLastPath]) -> SQLable {
        precondition(!names.isEmpty, "columns(names:) requires at least one column")

        var body: [SQLPart] = [SQLPartOperator.openSquareBracket]
        for (index, name) in names.enumerated() {
            if index > 0 {
                body.append(o: .comma, .space)
            }
            body.append(SQLPartSafeValue(name.lastPath))
        }
        body.append(o: .closeSquareBracket)
        return build(.columns, body: body)
    }

    /// Selects columns through the existing future-safe SQL lambda syntax.
    public static func columns(lambda: SQLable) -> SQLable {
        build(.columns, body: lambda.parts)
    }

    /// Expands COLUMNS arguments into the surrounding function call.
    public static func unpack(_ expression: SQLable) -> SQLable {
        build(.unpack, body: expression.parts)
    }
}
