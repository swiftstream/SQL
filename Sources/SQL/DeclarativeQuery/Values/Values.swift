import Foundation

public struct Values: SQLable {
    let rows: [Row]

    public init(@ValuesBuilder _ body: () -> ValuesBuilder.Result) {
        self.init(rows: body().rows)
    }

    public init(_ first: Row, _ rest: Row...) {
        self.init(rows: [first] + rest)
    }

    init(rows: [Row]) {
        self.rows = rows
    }

    public var parts: [SQLPart] {
        let rowPrefix = SQLHybridOperator(
            SQLPartOperator("("),
            SQLPartOperator("ROW("),
            SQLPartOperator("(")
        )
        var children: [SQLPart] = [
            SQLPartOperator("VALUES"),
            SQLPartOperator(" ")
        ]

        for (index, row) in rows.enumerated() {
            if index > 0 {
                children.append(SQLPartOperator(","))
                children.append(SQLPartOperator(" "))
            }
            children.append(rowPrefix)
            _appendRowFields(row.fields, to: &children)
            children.append(SQLPartOperator(")"))
        }

        return [SQLStructuralFramePart(region: .statement, children: children)]
    }
}
