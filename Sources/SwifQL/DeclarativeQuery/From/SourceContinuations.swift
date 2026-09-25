import Foundation

/// Request for the atomic SQL `WITH ORDINALITY` source continuation.
public struct WithOrdinalityRequest {
    public init() {}
}

/// Adds PostgreSQL's atomic `WITH ORDINALITY` continuation to a FROM source.
public func WithOrdinality() -> WithOrdinalityRequest {
    WithOrdinalityRequest()
}

/// Request for a name-only FROM alias column list.
public struct FromColumnsRequest {
    let names: [String]

    init(names: [String]) {
        self.names = names
    }
}

/// Adds an identifier-safe alias column list to the current FROM source.
public func Columns(_ names: String...) -> FromColumnsRequest {
    FromColumnsRequest(names: names)
}

/// Builds an identifier-safe alias column list for the current FROM source.
public func Columns(
    @IdentifierListBuilder _ content: () -> IdentifierListBuilder.Components
) -> FromColumnsRequest {
    let parts = content().parts
    let names = parts.compactMap { ($0 as? SwifQLPartAlias)?.alias }
    return FromColumnsRequest(names: names)
}
