//
//  Functions+Base64.swift
//  SwifQL
//

extension Fn {
    private static var fromBase64FunctionName: SQLHybridOperator {
        SQLHybridOperator(
            SQLPartOperator("from_base64"),
            SQLPartOperator("FROM_BASE64"),
            SQLPartOperator("from_base64")
        )
    }

    public static func fromBase64(_ value: SQLable) -> SQLable {
        var parts: [SQLPart] = [fromBase64FunctionName]
        parts.append(o: .openBracket)
        parts.append(contentsOf: value.parts)
        parts.append(o: .closeBracket)
        return SQLableParts(parts: parts)
    }
}
