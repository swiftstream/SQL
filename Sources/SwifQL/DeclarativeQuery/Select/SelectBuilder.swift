import Foundation

/// SELECT owns projection separators, postfix aliases, and the canonical leading
/// DISTINCT header. Other children remain ordered SQL fragments.
@resultBuilder
public enum SelectBuilder {
    public struct ProjectionItem: SQLBuilder.AliasableItem {
        public typealias Aliased = AliasedProjectionItem

        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }

        public func addingAlias(_ name: String) -> AliasedProjectionItem {
            var parts = snapshot
            parts.appendSpaceIfNeeded()
            parts.append(o: .as, .space)
            parts.append(SwifQLPartAlias(name))
            return AliasedProjectionItem(snapshotting: parts)
        }
    }

    public struct AliasedProjectionItem: SQLBuilder.FinalizableItem {
        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }
    }

    public struct Element {
        enum Kind {
            case projection([SwifQLPart])
            case modifier([SwifQLPart], carriesProjection: Bool)
            case alias([SwifQLPart])
        }

        let kind: Kind
    }

    public struct Components {
        let elements: [Element]

        init(elements: [Element]) {
            self.elements = elements
        }
    }

    public struct Result: SwifQLable, SQLBuilder.FinalizableItem {
        private let children: [SwifQLPart]

        init(children: [SwifQLPart]) {
            self.children = children
        }

        public var parts: [SwifQLPart] {
            [SwifQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SwifQLable { self }
    }

    public static func buildExpression(_ expression: any SwifQLable) -> Components {
        let parts = _SwifQLStructuralComposition.nestedEmbeddingParts(from: expression.parts)
        return Components(elements: [Element(kind: .projection(parts))])
    }

    public static func buildExpression(_ modifier: Distinct) -> Components {
        Components(elements: [
            Element(kind: .modifier(
                modifier.parts,
                carriesProjection: modifier._declarativeCarriesProjection
            ))
        ])
    }

    public static func buildExpression(_ modifier: DistinctOn) -> Components {
        Components(elements: [
            Element(kind: .modifier(modifier.parts, carriesProjection: false))
        ])
    }

    public static func buildExpression(_ request: SQLBuilder.AliasRequest) -> Components {
        Components(elements: [Element(kind: .alias([SwifQLPartOperator.as, SwifQLPartOperator.space, SwifQLPartAlias(request.name)]))])
    }

    public static func buildBlock() -> Components {
        Components(elements: [])
    }

    public static func buildBlock(_ components: Components...) -> Components {
        Components(elements: components.flatMap(\.elements))
    }

    public static func buildOptional(_ component: Components?) -> Components {
        component ?? Components(elements: [])
    }

    public static func buildEither(first component: Components) -> Components {
        component
    }

    public static func buildEither(second component: Components) -> Components {
        component
    }

    public static func buildArray(_ components: [Components]) -> Components {
        Components(elements: components.flatMap(\.elements))
    }

    public static func buildFinalResult(_ component: Components) -> Result {
        makeResult(component.elements)
    }

    private static func makeResult(_ elements: [Element]) -> Result {
        var children: [SwifQLPart] = []
        children.append(o: .select, .space)
        var hasListItem = false
        var previousCanOwnAlias = false

        for element in elements {
            switch element.kind {
            case .modifier(let parts, let carriesProjection):
                if !hasListItem {
                    children.appendSpaceIfNeeded()
                    children.append(contentsOf: parts)
                    if carriesProjection {
                        hasListItem = true
                        previousCanOwnAlias = true
                    } else {
                        previousCanOwnAlias = false
                    }
                } else {
                    children.append(o: .comma, .space)
                    var orderedParts = parts
                    if let last = orderedParts.last as? SwifQLPartOperator, last._value == " " {
                        orderedParts.removeLast()
                    }
                    children.append(contentsOf: orderedParts)
                    previousCanOwnAlias = carriesProjection
                }

            case .projection(let parts):
                guard !parts.isEmpty else {
                    previousCanOwnAlias = false
                    continue
                }
                if hasListItem {
                    children.append(o: .comma, .space)
                } else {
                    children.appendSpaceIfNeeded()
                }
                children.append(contentsOf: parts)
                hasListItem = true
                previousCanOwnAlias = true

            case .alias(let parts):
                if previousCanOwnAlias {
                    children.appendSpaceIfNeeded()
                    children.append(contentsOf: parts)
                } else {
                    if hasListItem {
                        children.append(o: .comma, .space)
                    } else {
                        children.appendSpaceIfNeeded()
                    }
                    children.append(contentsOf: parts)
                    hasListItem = true
                }
                previousCanOwnAlias = false
            }
        }

        return Result(children: children)
    }
}
