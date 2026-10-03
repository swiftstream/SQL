import Foundation

public enum RowFieldValue {
    case expression([SwifQLPart])
    case defaultKeyword
}

public protocol RowField {
    var rowFieldValue: RowFieldValue { get }
}

public struct DefaultFieldRequest: SwifQLable {
    public init() {}

    public var rowFieldValue: RowFieldValue { .defaultKeyword }

    public var parts: [SwifQLPart] { [SwifQLPartOperator.custom("DEFAULT")] }
}

public func Default() -> DefaultFieldRequest {
    DefaultFieldRequest()
}

public struct Row: SwifQLable {
    let fields: [RowFieldValue]

    public init(@RowBuilder _ body: () -> RowBuilder.Result) {
        self.init(fields: body().fields)
    }

    public init(_ first: any RowField, _ rest: any RowField...) {
        self.init(fields: ([first] + rest).map { $0.rowFieldValue })
    }

    init(fields: [RowFieldValue]) {
        self.fields = fields
    }

    public var parts: [SwifQLPart] {
        var result: [SwifQLPart] = [SwifQLPartOperator("ROW(")]
        _appendRowFields(fields, to: &result)
        result.append(SwifQLPartOperator(")"))
        return result
    }
}

func _appendRowFields(
    _ fields: [RowFieldValue],
    to parts: inout [SwifQLPart]
) {
    for (index, field) in fields.enumerated() {
        if index > 0 {
            parts.append(SwifQLPartOperator(","))
            parts.append(SwifQLPartOperator(" "))
        }

        switch field {
        case .expression(let fieldParts):
            precondition(!fieldParts.isEmpty, "A Row field must produce SQL parts.")
            parts.append(contentsOf: fieldParts)
        case .defaultKeyword:
            parts.append(SwifQLPartOperator("DEFAULT"))
        }
    }
}
