@resultBuilder
public enum ValuesBuilder {
    public struct Result {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }
    }

    public static func buildExpression(_ row: Row) -> Result {
        Result(rows: [row])
    }

    public static func buildBlock(_ components: Result...) -> Result {
        Result(rows: components.flatMap(\.rows))
    }

    public static func buildOptional(_ component: Result?) -> Result {
        component ?? Result(rows: [])
    }

    public static func buildEither(first component: Result) -> Result {
        component
    }

    public static func buildEither(second component: Result) -> Result {
        component
    }

    public static func buildArray(_ components: [Result]) -> Result {
        Result(rows: components.flatMap(\.rows))
    }
}
