import Foundation

/// SELECT owns projection separators, postfix aliases, and the canonical leading
/// DISTINCT header. Other children remain ordered SQL fragments.
@resultBuilder
public enum SelectBuilder {
    public struct ProjectionItem: SQLBuilder.AliasableItem {
        public typealias Aliased = AliasedProjectionItem

        private let snapshot: [SQLPart]

        init(snapshotting parts: [SQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: snapshot)
        }

        public func addingAlias(_ name: String) -> AliasedProjectionItem {
            var parts = snapshot
            parts.appendSpaceIfNeeded()
            parts.append(o: .as, .space)
            parts.append(SQLPartAlias(name))
            return AliasedProjectionItem(snapshotting: parts)
        }
    }

    public struct AliasedProjectionItem: SQLBuilder.FinalizableItem {
        private let snapshot: [SQLPart]

        init(snapshotting parts: [SQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: snapshot)
        }
    }

    public struct Element {
        enum Kind {
            case projection([SQLPart])
            case modifier([SQLPart], carriesProjection: Bool)
            case alias([SQLPart])
        }

        let kind: Kind
    }

    public struct Components {
        let elements: [Element]

        init(elements: [Element]) {
            self.elements = elements
        }
    }

    public struct Result: SQLable, SQLBuilder.FinalizableItem {
        private let children: [SQLPart]

        init(children: [SQLPart]) {
            self.children = children
        }

        public var parts: [SQLPart] {
            [SQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SQLable { self }
    }

    public static func buildExpression(_ expression: any SQLable) -> Components {
        let parts = _SQLStructuralComposition.nestedEmbeddingParts(from: expression.parts)
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
        Components(elements: [Element(kind: .alias([SQLPartOperator.as, SQLPartOperator.space, SQLPartAlias(request.name)]))])
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
        var children: [SQLPart] = []
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
                    if let last = orderedParts.last as? SQLPartOperator, last._value == " " {
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
