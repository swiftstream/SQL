import Foundation

/// Open identity for a clause whose semantic owner may be selected by a
/// structural SQL-region frame.
public struct SwifQLClauseKind: Hashable, Sendable {
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
public struct SwifQLClauseOwner: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public func renderScope(for kind: SwifQLClauseKind) -> SwifQLRenderScope {
        SwifQLRenderScope(
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
public enum SwifQLStructuralRegion: Hashable, Sendable {
    case statement
    case setResult
}

/// A value-semantic, readable SQL-region/set-result root in `SwifQLable.parts`.
public struct SwifQLStructuralFramePart: SwifQLPart {
    public let region: SwifQLStructuralRegion
    public let children: [SwifQLPart]
    public let owners: [SwifQLClauseKind: SwifQLClauseOwner]

    public init(
        region: SwifQLStructuralRegion,
        owners: [SwifQLClauseKind: SwifQLClauseOwner] = [:],
        children: [SwifQLPart] = []
    ) {
        self.region = region
        self.owners = owners
        self.children = children
    }

    public func owner(for kind: SwifQLClauseKind) -> SwifQLClauseOwner? {
        owners[kind]
    }

    internal func appending(
        _ parts: [SwifQLPart],
        owners newOwners: [SwifQLClauseKind: SwifQLClauseOwner] = [:]
    ) -> Self {
        guard !newOwners.isEmpty else {
            return Self(region: region, owners: owners, children: children + parts)
        }

        var mergedOwners = owners
        mergedOwners.merge(newOwners) { _, new in new }
        return Self(region: region, owners: mergedOwners, children: children + parts)
    }
}

enum _SwifQLStructuralSpacingPolicy {
    case normalizedContinuation
    case literal
}

enum _SwifQLStructuralComposition {
    private struct RootParts {
        let frame: SwifQLStructuralFramePart?
        let suffix: [SwifQLPart]

        var completeValue: [SwifQLPart] {
            guard let frame else { return suffix }
            return [frame] + suffix
        }
    }

    private static func decompose(_ parts: [SwifQLPart]) -> RootParts {
        guard let frame = parts.first as? SwifQLStructuralFramePart else {
            return RootParts(frame: nil, suffix: parts)
        }
        return RootParts(frame: frame, suffix: Array(parts.dropFirst()))
    }

    static func rootFrame(in parts: [SwifQLPart]) -> SwifQLStructuralFramePart? {
        decompose(parts).frame
    }

    static func currentOwner(
        in parts: [SwifQLPart],
        for kind: SwifQLClauseKind
    ) -> SwifQLClauseOwner? {
        rootFrame(in: parts)?.owner(for: kind)
    }

    /// Wraps the complete ordered value in one statement frame. When the value
    /// already has a statement root and sibling suffixes, both are retained as
    /// ordered children; the root frame and its ownership metadata stay intact.
    static func statementFrame(for query: SwifQLable) -> SwifQLStructuralFramePart {
        let value = decompose(query.parts)
        if let frame = value.frame,
           frame.region == .statement,
           value.suffix.isEmpty {
            return frame
        }

        return SwifQLStructuralFramePart(region: .statement, children: value.completeValue)
    }

    /// Keeps a root frame and every sibling suffix in their original order.
    static func statementValueParts(for query: SwifQLable) -> [SwifQLPart] {
        let value = decompose(query.parts)
        guard value.frame == nil else { return value.completeValue }
        return [statementFrame(for: query)]
    }

    /// Embeds a statement or set-result atomically while keeping its suffix
    /// outside the root frame's parentheses. Raw values are first framed as a
    /// statement because these consumers require a statement operand.
    static func nestedStatementValueParts(for query: SwifQLable) -> [SwifQLPart] {
        let value = decompose(query.parts)
        guard let frame = value.frame else {
            let parts: [SwifQLPart] = [
                SwifQLPartOperator.openBracket,
                statementFrame(for: query),
                SwifQLPartOperator.closeBracket
            ]
            return parts
        }
        let statementFrame = frame.region == .setResult
            ? SwifQLStructuralFramePart(region: .statement, children: [frame])
            : frame
        let parts: [SwifQLPart] = [
            SwifQLPartOperator.openBracket,
            statementFrame,
            SwifQLPartOperator.closeBracket
        ]
        return parts + value.suffix
    }

    /// With owns an outer `AS (...)` boundary. A suffix-bearing nested query
    /// needs its own frame parentheses before the suffix, while a suffix-free
    /// query keeps the established single pair.
    static func withQueryPartsInsideParentheses(for query: SwifQLable) -> [SwifQLPart] {
        let value = decompose(query.parts)
        guard !value.suffix.isEmpty else { return [statementFrame(for: query)] }
        guard value.frame != nil else { return [statementFrame(for: query)] }
        return nestedEmbeddingParts(from: value.completeValue)
    }

    static func setResult(from query: SwifQLable) -> SwifQLable {
        if let frame = rootFrame(in: query.parts), frame.region == .setResult {
            return query
        }

        return SwifQLableParts(rawParts: [
            SwifQLStructuralFramePart(
                region: .setResult,
                children: statementValueParts(for: query)
            )
        ])
    }

    /// Appends postfix structure outside root frames, normalizing its separator.
    static func appendingPostfix(
        _ postfixParts: [SwifQLPart],
        to base: SwifQLable
    ) -> SwifQLable {
        var baseParts = base.parts
        var suffix = postfixParts
        if (suffix.first as? SwifQLPartOperator)?._value == " " {
            if rootFrame(in: baseParts) != nil {
                baseParts = removingTrailingSpace(from: baseParts) ?? baseParts
            } else if removingTrailingSpace(from: baseParts) != nil {
                suffix.removeFirst()
            }
        }
        let combined = baseParts + suffix
        return rootFrame(in: baseParts) == nil
            ? SwifQLableParts(parts: combined)
            : SwifQLableParts(rawParts: combined)
    }

    private static func removingTrailingSpace(from parts: [SwifQLPart]) -> [SwifQLPart]? {
        guard let last = parts.last else {
            return nil
        }
        if let op = last as? SwifQLPartOperator, op._value == " " {
            return Array(parts.dropLast())
        }
        if let frame = last as? SwifQLStructuralFramePart {
            if let children = removingTrailingSpace(from: frame.children) {
                return Array(parts.dropLast()) + [
                    SwifQLStructuralFramePart(region: frame.region, owners: frame.owners, children: children)
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
        _ base: SwifQLable,
        parts newParts: [SwifQLPart],
        owners newOwners: [SwifQLClauseKind: SwifQLClauseOwner] = [:],
        spacing: _SwifQLStructuralSpacingPolicy = .normalizedContinuation
    ) -> SwifQLable {
        func continuationParts(
            _ parts: [SwifQLPart],
            after existingParts: [SwifQLPart]
        ) -> [SwifQLPart] {
            guard let first = parts.first as? SwifQLPartOperator,
                  first._value == " " else {
                return parts
            }

            if existingParts.isEmpty,
               !parts.isEmpty {
                return Array(parts.dropFirst())
            }

            if let last = existingParts.last as? SwifQLPartOperator,
               last._value == " " {
                return Array(parts.dropFirst())
            }

            return parts
        }

        func partsToAppend(after existingParts: [SwifQLPart]) -> [SwifQLPart] {
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
                return SwifQLableParts(rawParts: value.completeValue + appendedParts)
            }

            return SwifQLableParts(rawParts: [
                SwifQLStructuralFramePart(
                    region: .statement,
                    owners: newOwners,
                    children: value.completeValue + appendedParts
                )
            ])
        }

        let spacingParts = value.suffix.isEmpty ? root.children : value.suffix
        let appendedParts = partsToAppend(after: spacingParts)
        guard !value.suffix.isEmpty else {
            return SwifQLableParts(rawParts: [root.appending(appendedParts, owners: newOwners)])
        }

        let updatedRoot = root.appending([], owners: newOwners)
        return SwifQLableParts(rawParts: [updatedRoot] + value.suffix + appendedParts)
    }

    /// Reconstructs a receiver-preserving, append-only fluent operation.
    /// Callers must build `resultParts` by starting with `base.parts` and only
    /// appending a known continuation tail. That invariant makes the count
    /// split exact; this helper must not be used for prepend, infix, replace,
    /// or wrapper operations.
    static func reconstructingSequentialContinuation(
        from base: SwifQLable,
        resultParts: [SwifQLPart]
    ) -> SwifQLable {
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
        from base: SwifQLable,
        resultParts: [SwifQLPart]
    ) -> SwifQLable {
        let baseParts = base.parts
        precondition(resultParts.count >= baseParts.count, "Whole-value transform must retain the receiver prefix.")
        let transform = Array(resultParts.dropFirst(baseParts.count))
        let value = decompose(baseParts)
        guard value.frame != nil, value.suffix.isEmpty else {
            return SwifQLableParts(rawParts: value.completeValue + transform)
        }
        return append(base, parts: transform)
    }

    static func appendStatementContents(
        from fragment: SwifQLable,
        to base: SwifQLable
    ) -> SwifQLable {
        let value = decompose(fragment.parts)
        let contents: [SwifQLPart]
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
            parts: [SwifQLPartOperator.space] + contents
        )
    }

    /// Makes a stored statement or set result one nested expression/source,
    /// leaving any postfix suffix after the matching closing parenthesis.
    static func nestedEmbeddingParts(from parts: [SwifQLPart]) -> [SwifQLPart] {
        let value = decompose(parts)
        guard let frame = value.frame,
              frame.region == .statement || frame.region == .setResult else {
            return value.completeValue
        }
        let statementFrame = frame.region == .setResult
            ? SwifQLStructuralFramePart(region: .statement, children: [frame])
            : frame

        return [SwifQLPartOperator.openBracket, statementFrame, SwifQLPartOperator.closeBracket]
            + value.suffix
    }
}

extension SwifQLable {
    /// Continues the current root SQL region without inspecting nested
    /// frames or semantic history.
    public func structurallyAppending(_ fragment: SwifQLable) -> SwifQLable {
        _SwifQLStructuralComposition.append(self, parts: fragment.parts)
    }

    /// Reads ownership only from the current root frame.
    public func structuralOwner(for kind: SwifQLClauseKind) -> SwifQLClauseOwner? {
        _SwifQLStructuralComposition.currentOwner(in: parts, for: kind)
    }
}

extension SwifQLableParts {
    internal init(rawParts: [SwifQLPart]) {
        self.parts = rawParts
    }
}
