import Foundation

extension SQLBuilder {
    /// Typed aliasability contract for postfix `As("alias")` continuation.
    ///
    /// An open owner stays statically typed. `As` attaches only through this
    /// protocol. An already-aliased item is only `FinalizableItem`, so repeated
    /// aliasing rejects structurally. Orphan/after-finalized-branch aliasing is
    /// rejected by the consuming result builder's typed transitions, not by
    /// token scanning or ambient state.
    public protocol AliasableItem: FinalizableItem {
        associatedtype Aliased: FinalizableItem
        func addingAlias(_ name: String) -> Aliased
    }

    /// Immutable typed alias request produced by `As(_:)`.
    ///
    /// Deliberately public under DESIGN-016/018 so a downstream package may
    /// conform its own typed authoring item to `AliasableItem` and consume the
    /// request in a compatible custom result-builder extension.
    public struct AliasRequest {
        public let name: String

        public init(_ name: String) {
            self.name = name
        }
    }
}

/// Typed postfix alias request.
///
/// Owner-specific result builders consume this request through
/// `SQLBuilder.AliasableItem.addingAlias(_:)`. DQ-02 does not attach it to
/// arbitrary `FinalizableItem` values and does not add clause-owner states.
public func As(_ name: String) -> SQLBuilder.AliasRequest {
    SQLBuilder.AliasRequest(name)
}
