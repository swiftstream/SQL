import Foundation

extension SQLBuilder {
    /// Typed aliasability contract for postfix `As("alias")` continuation.
    ///
    /// Within a specialized builder, an open owner stays statically typed and
    /// `As` attaches through this protocol. An already-aliased item is only
    /// `FinalizableItem`, so repeated aliasing rejects structurally. Alias
    /// requests left unattached remain independently renderable
    /// `AS <identifier>` fragments.
    public protocol AliasableItem: FinalizableItem {
        associatedtype Aliased: FinalizableItem
        func addingAlias(_ name: String) -> Aliased
    }

    /// Immutable typed alias request produced by `As(_:)`.
    ///
    /// Renders independently as `AS <identifier>` with identifier-safe
    /// lowering through `SQLPartAlias`, including standalone/root use.
    /// Specialized builders may also recognize it as a local postfix
    /// continuation and preserve local alias ownership where useful.
    ///
    /// Deliberately public under DESIGN-016/018 so a downstream package may
    /// conform its own typed authoring item to `AliasableItem` and consume the
    /// request in a compatible custom result-builder extension.
    public struct AliasRequest: SQLable {
        public let name: String

        public init(_ name: String) {
            self.name = name
        }

        public var parts: [SQLPart] {
            [SQLPartOperator.custom("AS"), SQLPartOperator.space, SQLPartAlias(name)]
        }
    }
}

/// Typed postfix alias request.
///
/// The request is an ordinary independently renderable `SQLable`
/// fragment, valid standalone/at root. Specialized result builders may
/// still consume it through `SQLBuilder.AliasableItem.addingAlias(_:)` as
/// a local postfix continuation.
public func As(_ name: String) -> SQLBuilder.AliasRequest {
    SQLBuilder.AliasRequest(name)
}
