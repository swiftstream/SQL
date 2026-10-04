//
//  Functions+Table.swift
//  SwifQL
//

extension Fn.Name {
    public static let readCSV = Self("read_csv")
    public static let readParquet = Self("read_parquet")
    public static let readJSON = Self("read_json")
    public static let glob = Self("glob")
}

private func appendTableFunctionOptions(
    _ options: [TableFunctionOption],
    to parts: inout [SQLPart]
) {
    guard !options.isEmpty else { return }

    parts.append(o: .comma, .space)
    for (index, option) in options.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(contentsOf: option.parts)
    }
}

extension Fn {
    public static func readCSV(
        _ path: SQLable,
        options: TableFunctionOption...
    ) -> SQLable {
        readCSV(path, options: options)
    }

    public static func readCSV(
        _ path: SQLable,
        options: [TableFunctionOption]
    ) -> SQLable {
        var parts = path.parts
        appendTableFunctionOptions(options, to: &parts)
        return build(.readCSV, body: parts)
    }

    public static func readParquet(
        _ path: SQLable,
        options: TableFunctionOption...
    ) -> SQLable {
        readParquet(path, options: options)
    }

    public static func readParquet(
        _ path: SQLable,
        options: [TableFunctionOption]
    ) -> SQLable {
        var parts = path.parts
        appendTableFunctionOptions(options, to: &parts)
        return build(.readParquet, body: parts)
    }

    public static func readJSON(
        _ path: SQLable,
        options: TableFunctionOption...
    ) -> SQLable {
        readJSON(path, options: options)
    }

    public static func readJSON(
        _ path: SQLable,
        options: [TableFunctionOption]
    ) -> SQLable {
        var parts = path.parts
        appendTableFunctionOptions(options, to: &parts)
        return build(.readJSON, body: parts)
    }

    public static func glob(_ pattern: SQLable) -> SQLable {
        build(.glob, body: pattern.parts)
    }
}
