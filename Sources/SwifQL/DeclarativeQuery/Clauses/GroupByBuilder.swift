import Foundation

/// Result builder for ordered GROUP BY expressions.
@resultBuilder
public enum GroupByBuilder {
    /// Public inferred builder product; expression storage stays module-local.
    public struct Result {
        let expressionParts: [[SwifQLPart]]

        init(expressionParts: [[SwifQLPart]]) {
            self.expressionParts = expressionParts
        }
    }

    private static func expression(_ value: any SwifQLable) -> Result {
        let parts = value.parts
        return Result(expressionParts: parts.isEmpty ? [] : [parts])
    }

    public static func buildExpression(_ expression: any SwifQLable) -> Result {
        self.expression(expression)
    }

    public static func buildExpression(_ expression: GroupingSets) -> Result {
        self.expression(expression)
    }

    public static func buildExpression(_ expression: Rollup) -> Result {
        self.expression(expression)
    }

    public static func buildExpression(_ expression: Cube) -> Result {
        self.expression(expression)
    }

    public static func buildBlock(_ components: Result...) -> Result {
        Result(expressionParts: components.flatMap(\.expressionParts))
    }

    public static func buildOptional(_ component: Result?) -> Result {
        component ?? Result(expressionParts: [])
    }

    public static func buildEither(first component: Result) -> Result {
        component
    }

    public static func buildEither(second component: Result) -> Result {
        component
    }

    public static func buildArray(_ components: [Result]) -> Result {
        Result(expressionParts: components.flatMap(\.expressionParts))
    }
}
