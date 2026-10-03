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
        self.rows = rows
    }

    public var parts: [SwifQLPart] {
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
