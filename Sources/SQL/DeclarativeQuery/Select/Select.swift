import Foundation

/// Declarative SELECT authoring entry.
///
/// Coexists with the existing `Select` value and legacy `Select(...)` functions.
/// Lowers to ordinary parts plus exactly one statement structural frame.
public func Select(
    @SelectBuilder _ content: () -> SelectBuilder.Result
) -> SelectBuilder.Result {
    content()
}

extension SQLable {
    /// Identifier-safe fluent alias (DESIGN-021).
    ///
    /// Wins overload resolution for `.as("alias")` over the existing generic
    /// `.as(_ expression: SQLable)` (which would route `String` through
    /// ordinary value semantics). Binds zero alias values.
    public func `as`(_ alias: String) -> SQLable {
        var parts: [SQLPart] = []
        parts.append(o: .space, .as, .space)
        parts.append(SQLPartAlias(alias))
        return _SQLStructuralComposition.appendingPostfix(parts, to: self)
    }
}
