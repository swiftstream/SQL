import Foundation

/// Builder for `DISTINCT ON` key lists.
///
/// Each key expression is snapshotted exactly once. Empty bodies are rejected
/// structurally: `buildBlock` requires at least one key, and no zero-key
/// `DistinctOn()` initializer exists.
@resultBuilder
public enum DistinctOnBuilder {
    /// Public builder product holding one or more snapshotted key fragments.
    public struct Components: SwifQLable {
        let keySnapshots: [[SwifQLPart]]

        init(keySnapshots: [[SwifQLPart]]) {
            self.keySnapshots = keySnapshots
        }

        public var parts: [SwifQLPart] {
            var parts: [SwifQLPart] = []
            for (index, key) in keySnapshots.enumerated() {
                if index > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: key)
            }
            return parts
        }
    }

    public static func buildExpression(
        _ expression: SwifQLable
    ) -> Components {
        Components(keySnapshots: [expression.parts])
    }

    public static func buildBlock(
        _ first: Components,
        _ rest: Components...
    ) -> Components {
        Components(
            keySnapshots: first.keySnapshots + rest.flatMap { $0.keySnapshots }
        )
    }
}

/// Canonical compound SELECT modifier `DISTINCT ON (key1, key2, ...)`.
///
/// PostgreSQL/Duck token identity only. No MySQL emulation, alias conversion,
/// value conversion, GROUP BY rewrite, or window fallback.
public struct DistinctOn: SwifQLable {
    private let keySnapshots: [[SwifQLPart]]

    public var parts: [SwifQLPart] {
        var parts: [SwifQLPart] = []
        parts.append(o: .distinct)
        parts.append(o: .space)
        parts.append(o: .on)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        for (index, key) in keySnapshots.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: key)
        }
        parts.append(o: .closeBracket)
        return parts
    }

    /// Builder-first form: `DistinctOn { User.$country; User.$city }`.
    public init(
        @DistinctOnBuilder _ content: () -> DistinctOnBuilder.Components
    ) {
        self.keySnapshots = content().keySnapshots
    }

    /// Concise form: `DistinctOn(User.$country, User.$city)`.
    ///
    /// At least one key is mandatory. Each key `parts` is evaluated exactly once.
    public init(
        _ first: SwifQLable,
        _ rest: SwifQLable...
    ) {
        var snapshots: [[SwifQLPart]] = [first.parts]
        for key in rest {
            snapshots.append(key.parts)
        }
        self.keySnapshots = snapshots
    }
}
