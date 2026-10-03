import Foundation

@resultBuilder
public enum InsertBuilder {
    public struct Fragment {
        enum Content {
            case columns(FromColumnsRequest)
            case values(Values)
        }

        let content: Content

        init(_ content: Content) {
            self.content = content
        }
    }

    public struct Result {
        let fragments: [Fragment]

        init(fragments: [Fragment]) {
            self.fragments = fragments
        }
    }

    public static func buildExpression(_ columns: FromColumnsRequest) -> Fragment {
        Fragment(.columns(columns))
    }

    public static func buildExpression(_ values: Values) -> Fragment {
        Fragment(.values(values))
    }

    public static func buildBlock() -> Result {
        Result(fragments: [])
    }

    public static func buildPartialBlock(first fragment: Fragment) -> Result {
        Result(fragments: [fragment])
    }

    public static func buildPartialBlock(
        accumulated: Result,
        next fragment: Fragment
    ) -> Result {
        Result(fragments: accumulated.fragments + [fragment])
    }

    public static func buildOptional(_ component: Result?) -> Result {
        component ?? Result(fragments: [])
    }

    public static func buildEither(first component: Result) -> Result {
        component
    }

    public static func buildEither(second component: Result) -> Result {
        component
    }

    public static func buildArray(_ components: [Result]) -> Result {
        Result(fragments: components.flatMap(\.fragments))
    }
}

public struct Insert: SwifQLable {
    private let targetParts: [SwifQLPart]
    private let bodyFragments: [InsertBuilder.Fragment]

    public init(
        _ target: any SwifQLable,
        @InsertBuilder _ body: () -> InsertBuilder.Result
    ) {
        self.targetParts = target.parts
        self.bodyFragments = body().fragments
    }

    public var parts: [SwifQLPart] {
        var result: [SwifQLPart] = []
        result.append(o: .insert, .space, .into, .space)
        result.append(contentsOf: targetParts)

        for fragment in bodyFragments {
            switch fragment.content {
            case .columns(let request):
                guard !request.names.isEmpty else { continue }
                result.append(o: .space, .openBracket)
                for (index, name) in request.names.enumerated() {
                    if index > 0 { result.append(o: .comma, .space) }
                    result.append(SwifQLPartAlias(name))
                }
                result.append(o: .closeBracket)

            case .values(let values):
                result.append(o: .space, .custom("VALUES"), .space)
                let rowPrefix = SwifQLHybridOperator(
                    SwifQLPartOperator("("),
                    SwifQLPartOperator("ROW("),
                    SwifQLPartOperator("(")
                )
                for (index, row) in values.rows.enumerated() {
                    if index > 0 { result.append(o: .comma, .space) }
                    result.append(rowPrefix)
                    _appendRowFields(row.fields, to: &result)
                    result.append(o: .closeBracket)
                }
            }
        }
        return result
    }
}
