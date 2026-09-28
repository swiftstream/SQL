import Foundation

public struct Values: SwifQLable {
    let rows: [Row]

    public init(@ValuesBuilder _ body: () -> ValuesBuilder.Result) {
        self.init(rows: body().rows)
    }

    public init(_ first: Row, _ rest: Row...) {
        self.init(rows: [first] + rest)
    }

    init(rows: [Row]) {
        precondition(!rows.isEmpty, "VALUES must contain at least one Row.")

        guard let arity = rows.first?.fields.count else {
            preconditionFailure("VALUES must contain at least one Row.")
        }
        precondition(arity > 0, "A VALUES Row must contain at least one field.")
        precondition(
            rows.allSatisfy { $0.fields.count == arity },
            "Every Row in VALUES must have the same number of fields."
        )

        self.rows = rows
    }

    public var parts: [SwifQLPart] {
        precondition(
            rows.allSatisfy { row in
                row.fields.allSatisfy { field in
                    if case .defaultKeyword = field { return false }
                    return true
                }
            },
            "Default() can only be lowered by its INSERT owner."
        )

        let rowPrefix = SwifQLHybridOperator(
            SwifQLPartOperator("("),
            SwifQLPartOperator("ROW("),
            SwifQLPartOperator("(")
        )
        var children: [SwifQLPart] = [
            SwifQLPartOperator("VALUES"),
            SwifQLPartOperator(" ")
        ]

        for (index, row) in rows.enumerated() {
            if index > 0 {
                children.append(SwifQLPartOperator(","))
                children.append(SwifQLPartOperator(" "))
            }
            children.append(rowPrefix)
            _appendRowFields(row.fields, to: &children)
            children.append(SwifQLPartOperator(")"))
        }

        return [SwifQLStructuralFramePart(region: .statement, children: children)]
    }
}
