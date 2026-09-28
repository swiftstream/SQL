import Foundation

/// Result builder for ordered existing `OrderByItem` values.
@resultBuilder
public enum OrderByBuilder {
    /// Public inferred builder product; item storage stays module-local.
    public struct Result {
        let items: [OrderByItem]

        init(items: [OrderByItem]) {
            self.items = items
        }
    }

    public static func buildExpression(_ item: OrderByItem) -> Result {
        Result(items: [item])
    }

    public static func buildBlock(_ components: Result...) -> Result {
        Result(items: components.flatMap(\.items))
    }

    public static func buildOptional(_ component: Result?) -> Result {
        component ?? Result(items: [])
    }

    public static func buildEither(first component: Result) -> Result {
        component
    }

    public static func buildEither(second component: Result) -> Result {
        component
    }

    public static func buildArray(_ components: [Result]) -> Result {
        Result(items: components.flatMap(\.items))
    }
}
