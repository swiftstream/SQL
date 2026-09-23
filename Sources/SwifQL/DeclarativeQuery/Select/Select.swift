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

extension SwifQLable {
    /// Identifier-safe fluent alias (DESIGN-021).
    ///
    /// Wins overload resolution for `.as("alias")` over the existing generic
    /// `.as(_ expression: SwifQLable)` (which would route `String` through
    /// ordinary value semantics). Binds zero alias values. The existing `=>`
    /// operator and generic `.as(SwifQLable)` remain unchanged.
    public func `as`(_ alias: String) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .as, .space)
        parts.append(SwifQLPartAlias(alias))
        return SwifQLableParts(parts: parts)
    }
}
