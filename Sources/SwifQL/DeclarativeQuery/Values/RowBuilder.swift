@resultBuilder
public enum RowBuilder {
    public struct Result {
        let fields: [RowFieldValue]

        init(fields: [RowFieldValue]) {
            self.fields = fields
        }
    }

    public static func buildExpression(_ field: any RowField) -> Result {
        Result(fields: [field.rowFieldValue])
    }

    public static func buildBlock(_ components: Result...) -> Result {
        Result(fields: components.flatMap(\.fields))
    }

    public static func buildOptional(_ component: Result?) -> Result {
        component ?? Result(fields: [])
    }

    public static func buildEither(first component: Result) -> Result {
        component
    }

    public static func buildEither(second component: Result) -> Result {
        component
    }

    public static func buildArray(_ components: [Result]) -> Result {
        Result(fields: components.flatMap(\.fields))
    }
}
