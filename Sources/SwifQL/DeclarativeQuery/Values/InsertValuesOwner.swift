import Foundation

@resultBuilder
public enum InsertBuilder {
    public struct ColumnsState {
        let names: [String]

        init(names: [String]) {
            precondition(!names.isEmpty, "INSERT must contain at least one target column.")
            self.names = names
        }
    }

    public struct Result {
        let columns: ColumnsState
        let values: Values

        init(columns: ColumnsState, values: Values) {
            self.columns = columns
            self.values = values
        }
    }

    public static func buildExpression(_ columns: FromColumnsRequest) -> FromColumnsRequest {
        columns
    }

    public static func buildExpression(_ values: Values) -> Values {
        values
    }

    public static func buildPartialBlock(first columns: FromColumnsRequest) -> ColumnsState {
        ColumnsState(names: columns.names)
    }

    public static func buildPartialBlock(
        accumulated: ColumnsState,
        next values: Values
    ) -> Result {
        Result(columns: accumulated, values: values)
    }
}

public struct Insert: SwifQLable {
    private let targetParts: [SwifQLPart]
    private let columns: [String]
    private let values: Values

    public init(
        _ target: any SwifQLable,
        @InsertBuilder _ body: () -> InsertBuilder.Result
    ) {
        let result = body()
        precondition(!result.columns.names.isEmpty, "INSERT must contain at least one target column.")
        precondition(!result.values.rows.isEmpty, "INSERT must contain at least one VALUES row.")
        precondition(
            result.values.rows.allSatisfy { $0.fields.count == result.columns.names.count },
            "Every INSERT VALUES row must match the target column count."
        )

        self.targetParts = target.parts
        self.columns = result.columns.names
        self.values = result.values
    }

    public var parts: [SwifQLPart] {
        precondition(!columns.isEmpty, "INSERT must contain at least one target column.")
        precondition(!values.rows.isEmpty, "INSERT must contain at least one VALUES row.")
        precondition(
            values.rows.allSatisfy { $0.fields.count == columns.count },
            "Every INSERT VALUES row must match the target column count."
        )

        var result: [SwifQLPart] = []
        result.append(o: .insert, .space, .into, .space)
        result.append(contentsOf: targetParts)
        result.append(o: .space, .openBracket)
        for (index, name) in columns.enumerated() {
            if index > 0 {
                result.append(o: .comma, .space)
            }
            result.append(SwifQLPartAlias(name))
        }
        result.append(o: .closeBracket, .space, .values, .space)

        let rowPrefix = SwifQLHybridOperator(
            SwifQLPartOperator("("),
            SwifQLPartOperator("ROW("),
            SwifQLPartOperator("(")
        )
        for (index, row) in values.rows.enumerated() {
            if index > 0 {
                result.append(o: .comma, .space)
            }
            result.append(rowPrefix)
            _appendInsertOwnedFields(row.fields, to: &result)
            result.append(o: .closeBracket)
        }
        return result
    }
}

private func _appendInsertOwnedFields(
    _ fields: [RowFieldValue],
    to parts: inout [SwifQLPart]
) {
    precondition(!fields.isEmpty, "An INSERT VALUES row must contain at least one field.")

    for (index, field) in fields.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }

        switch field {
        case .expression(let fieldParts):
            precondition(!fieldParts.isEmpty, "An INSERT VALUES field must produce SQL parts.")
            parts.append(contentsOf: fieldParts)
        case .defaultKeyword:
            parts.append(SwifQLPartOperator("DEFAULT"))
        }
    }
}
