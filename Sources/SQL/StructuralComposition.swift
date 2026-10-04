import Foundation

/// Open identity for a clause whose semantic owner may be selected by a
/// structural SQL-region frame.
public struct SQLClauseKind: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let on = Self(namespace: "swifql", name: "on")
    public static let using = Self(namespace: "swifql", name: "using")
    public static let groupBy = Self(namespace: "swifql", name: "groupBy")
    public static let orderBy = Self(namespace: "swifql", name: "orderBy")
}

/// Open identity for the structural SQL region that owns a clause.
public struct SQLClauseOwner: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public func renderScope(for kind: SQLClauseKind) -> SQLRenderScope {
        SQLRenderScope(
            namespace: "swifql.clause-owner",
            name: "\(namespace).\(name).\(kind.namespace).\(kind.name)",
            identityComponents: [
                .init(namespace: namespace, name: name),
                .init(namespace: kind.namespace, name: kind.name)
            ]
        )
    }
}

/// The real SQL-region boundaries represented by the structural composition
/// layer. Ordinary expression parentheses are not structural regions.
public enum SQLStructuralRegion: Hashable, Sendable {
    case statement
    case setResult
}

/// A value-semantic, readable SQL-region/set-result root in `SQLable.parts`.
public struct SQLStructuralFramePart: SQLPart {
    public let region: SQLStructuralRegion
    public let children: [SQLPart]
    public let owners: [SQLClauseKind: SQLClauseOwner]

    public init(
        region: SQLStructuralRegion,
        owners: [SQLClauseKind: SQLClauseOwner] = [:],
        children: [SQLPart] = []
    ) {
        self.region = region
        self.owners = owners
        self.children = children
    }

    public func owner(for kind: SQLClauseKind) -> SQLClauseOwner? {
        owners[kind]
    }

    internal func appending(
        _ parts: [SQLPart],
        owners newOwners: [SQLClauseKind: SQLClauseOwner] = [:]
    ) -> Self {
        guard !newOwners.isEmpty else {
            return Self(region: region, owners: owners, children: children + parts)
        }

        var mergedOwners = owners
        mergedOwners.merge(newOwners) { _, new in new }
        return Self(region: region, owners: mergedOwners, children: children + parts)
    }
}

enum _SQLStructuralSpacingPolicy {
    case normalizedContinuation
    case literal
}

enum _SQLStructuralComposition {
    private struct RootParts {
        let frame: SQLStructuralFramePart?
        let suffix: [SQLPart]

        var completeValue: [SQLPart] {
            guard let frame else { return suffix }
            return [frame] + suffix
        }
    }

    private static func decompose(_ parts: [SQLPart]) -> RootParts {
        guard let frame = parts.first as? SQLStructuralFramePart else {
            return RootParts(frame: nil, suffix: parts)
        }
        return RootParts(frame: frame, suffix: Array(parts.dropFirst()))
    }

    static func rootFrame(in parts: [SQLPart]) -> SQLStructuralFramePart? {
        decompose(parts).frame
    }

    static func currentOwner(
        in parts: [SQLPart],
        for kind: SQLClauseKind
    ) -> SQLClauseOwner? {
        rootFrame(in: parts)?.owner(for: kind)
    }

    /// Wraps the complete ordered value in one statement frame. When the value
    /// already has a statement root and sibling suffixes, both are retained as
    /// ordered children; the root frame and its ownership metadata stay intact.
    static func statementFrame(for query: SQLable) -> SQLStructuralFramePart {
        let value = decompose(query.parts)
        if let frame = value.frame,
           frame.region == .statement,
           value.suffix.isEmpty {
            return frame
        }

        return SQLStructuralFramePart(region: .statement, children: value.completeValue)
    }

    /// Keeps a root frame and every sibling suffix in their original order.
    static func statementValueParts(for query: SQLable) -> [SQLPart] {
        let value = decompose(query.parts)
        guard value.frame == nil else { return value.completeValue }
        return [statementFrame(for: query)]
    }

    /// Embeds a statement or set-result atomically while keeping its suffix
    /// outside the root frame's parentheses. Raw values are first framed as a
    /// statement because these consumers require a statement operand.
    static func nestedStatementValueParts(for query: SQLable) -> [SQLPart] {
        let value = decompose(query.parts)
        guard let frame = value.frame else {
            let parts: [SQLPart] = [
                SQLPartOperator.openBracket,
                statementFrame(for: query),
                SQLPartOperator.closeBracket
            ]
            return parts
        }
        let statementFrame = frame.region == .setResult
            ? SQLStructuralFramePart(region: .statement, children: [frame])
            : frame
        let parts: [SQLPart] = [
            SQLPartOperator.openBracket,
            statementFrame,
            SQLPartOperator.closeBracket
        ]
        return parts + value.suffix
    }

    /// With owns an outer `AS (...)` boundary. A suffix-bearing nested query
    /// needs its own frame parentheses before the suffix, while a suffix-free
    /// query keeps the established single pair.
    static func withQueryPartsInsideParentheses(for query: SQLable) -> [SQLPart] {
        let value = decompose(query.parts)
        guard !value.suffix.isEmpty else { return [statementFrame(for: query)] }
        guard value.frame != nil else { return [statementFrame(for: query)] }
        return nestedEmbeddingParts(from: value.completeValue)
    }

    static func setResult(from query: SQLable) -> SQLable {
        if let frame = rootFrame(in: query.parts), frame.region == .setResult {
            return query
        }

        return SQLableParts(rawParts: [
            SQLStructuralFramePart(
                region: .setResult,
                children: statementValueParts(for: query)
            )
        ])
    }

    /// Appends postfix structure outside root frames, normalizing its separator.
    static func appendingPostfix(
        _ postfixParts: [SQLPart],
        to base: SQLable
    ) -> SQLable {
        var baseParts = base.parts
        var suffix = postfixParts
        if (suffix.first as? SQLPartOperator)?._value == " " {
            if rootFrame(in: baseParts) != nil {
                baseParts = removingTrailingSpace(from: baseParts) ?? baseParts
            } else if removingTrailingSpace(from: baseParts) != nil {
                suffix.removeFirst()
            }
        }
        let combined = baseParts + suffix
        return rootFrame(in: baseParts) == nil
            ? SQLableParts(parts: combined)
            : SQLableParts(rawParts: combined)
    }

    private static func removingTrailingSpace(from parts: [SQLPart]) -> [SQLPart]? {
        guard let last = parts.last else {
            return nil
        }
        if let op = last as? SQLPartOperator, op._value == " " {
            return Array(parts.dropLast())
        }
        if let frame = last as? SQLStructuralFramePart {
            if let children = removingTrailingSpace(from: frame.children) {
                return Array(parts.dropLast()) + [
                    SQLStructuralFramePart(region: frame.region, owners: frame.owners, children: children)
                ]
            }
            if frame.children.isEmpty,
               let prefix = removingTrailingSpace(from: Array(parts.dropLast())) {
                return prefix + [frame]
            }
        }
        return nil
    }

    static func append(
        _ base: SQLable,
        parts newParts: [SQLPart],
        owners newOwners: [SQLClauseKind: SQLClauseOwner] = [:],
        spacing: _SQLStructuralSpacingPolicy = .normalizedContinuation
    ) -> SQLable {
        func continuationParts(
            _ parts: [SQLPart],
            after existingParts: [SQLPart]
        ) -> [SQLPart] {
            guard let first = parts.first as? SQLPartOperator,
                  first._value == " " else {
                return parts
            }

            if existingParts.isEmpty,
               !parts.isEmpty {
                return Array(parts.dropFirst())
            }

            if let last = existingParts.last as? SQLPartOperator,
               last._value == " " {
                return Array(parts.dropFirst())
            }

            return parts
        }

        func partsToAppend(after existingParts: [SQLPart]) -> [SQLPart] {
            switch spacing {
            case .normalizedContinuation:
                return continuationParts(newParts, after: existingParts)
            case .literal:
                return newParts
            }
        }

        let value = decompose(base.parts)
        guard let root = value.frame else {
            let appendedParts = partsToAppend(after: value.completeValue)
            guard !newOwners.isEmpty else {
                return SQLableParts(rawParts: value.completeValue + appendedParts)
            }

            return SQLableParts(rawParts: [
                SQLStructuralFramePart(
                    region: .statement,
                    owners: newOwners,
                    children: value.completeValue + appendedParts
                )
            ])
        }

        let spacingParts = value.suffix.isEmpty ? root.children : value.suffix
        let appendedParts = partsToAppend(after: spacingParts)
        guard !value.suffix.isEmpty else {
            return SQLableParts(rawParts: [root.appending(appendedParts, owners: newOwners)])
        }

        let updatedRoot = root.appending([], owners: newOwners)
        return SQLableParts(rawParts: [updatedRoot] + value.suffix + appendedParts)
    }

    /// Reconstructs a receiver-preserving, append-only fluent operation.
    /// Callers must build `resultParts` by starting with `base.parts` and only
    /// appending a known continuation tail. That invariant makes the count
    /// split exact; this helper must not be used for prepend, infix, replace,
    /// or wrapper operations.
    static func reconstructingSequentialContinuation(
        from base: SQLable,
        resultParts: [SQLPart]
    ) -> SQLable {
        let baseParts = base.parts
        precondition(resultParts.count >= baseParts.count, "Sequential continuation must retain the receiver prefix.")
        let continuation = Array(resultParts.dropFirst(baseParts.count))
        return append(base, parts: continuation)
    }

    /// Reconstructs an expression transform that follows the complete current
    /// value. A bare structural root keeps the legacy in-root representation;
    /// when the root already has siblings, preserve those siblings before the
    /// transform so the operation cannot re-own or fold them.
    static func reconstructingWholeValueTransform(
        from base: SQLable,
        resultParts: [SQLPart]
    ) -> SQLable {
        let baseParts = base.parts
        precondition(resultParts.count >= baseParts.count, "Whole-value transform must retain the receiver prefix.")
        let transform = Array(resultParts.dropFirst(baseParts.count))
        let value = decompose(baseParts)
        guard value.frame != nil, value.suffix.isEmpty else {
            return SQLableParts(rawParts: value.completeValue + transform)
        }
        return append(base, parts: transform)
    }

    static func appendStatementContents(
        from fragment: SQLable,
        to base: SQLable
    ) -> SQLable {
        let value = decompose(fragment.parts)
        let contents: [SQLPart]
        if let frame = value.frame, frame.region == .statement {
            contents = frame.children + value.suffix
        } else {
            contents = value.completeValue
        }

        guard !contents.isEmpty else {
            return base
        }

        return append(
            base,
            parts: [SQLPartOperator.space] + contents
        )
    }

    /// Makes a stored statement or set result one nested expression/source,
    /// leaving any postfix suffix after the matching closing parenthesis.
    static func nestedEmbeddingParts(from parts: [SQLPart]) -> [SQLPart] {
        let value = decompose(parts)
        guard let frame = value.frame,
              frame.region == .statement || frame.region == .setResult else {
            return value.completeValue
        }
        let statementFrame = frame.region == .setResult
            ? SQLStructuralFramePart(region: .statement, children: [frame])
            : frame

        return [SQLPartOperator.openBracket, statementFrame, SQLPartOperator.closeBracket]
            + value.suffix
    }
}

extension SQLable {
    /// Continues the current root SQL region without inspecting nested
    /// frames or semantic history.
    public func structurallyAppending(_ fragment: SQLable) -> SQLable {
        _SQLStructuralComposition.append(self, parts: fragment.parts)
    }

    /// Reads ownership only from the current root frame.
    public func structuralOwner(for kind: SQLClauseKind) -> SQLClauseOwner? {
        _SQLStructuralComposition.currentOwner(in: parts, for: kind)
    }
}

extension SQLableParts {
    internal init(rawParts: [SQLPart]) {
        self.parts = rawParts
    }
}
