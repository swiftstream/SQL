import Foundation

/// Reusable identifier-name list builder for later column-list owners.
///
/// Every `String` child is an SQL identifier NAME and lowers through existing
/// `SQLPartAlias` identifier rendering. It never lowers through ordinary
/// String value semantics and never binds values.
@resultBuilder
public enum IdentifierListBuilder {
    /// Public builder product for reusable clause owners.
    public struct Components: SQLable {
        let names: [String]

        init(names: [String]) {
            self.names = names
        }

        public var parts: [SQLPart] {
            guard !names.isEmpty else {
                return []
            }

            var parts: [SQLPart] = []
            for (index, name) in names.enumerated() {
                if index > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(SQLPartAlias(name))
            }
            return parts
        }
    }

    public static func buildExpression(
        _ name: String
    ) -> Components {
        Components(names: [name])
    }

    public static func buildExpression(
        _ path: any SQLable
    ) -> Components {
        guard let name = structuralColumnName(from: path) else {
            preconditionFailure("Identifier lists accept only a single structural column path or a String name.")
        }

        return Components(names: [name])
    }

    static func structuralColumnName(from path: any SQLable) -> String? {
        let parts = path.parts
        guard parts.count == 1,
              let keyPath = parts.first as? SQLPartKeyPath,
              !keyPath.asText,
              let name = keyPath.paths.last,
              !name.isEmpty else {
            return nil
        }

        return name
    }

    public static func buildBlock(
        _ components: Components...
    ) -> Components {
        Components(names: components.flatMap { $0.names })
    }

    public static func buildOptional(
        _ component: Components?
    ) -> Components {
        component ?? Components(names: [])
    }

    public static func buildEither(
        first component: Components
    ) -> Components {
        component
    }

    public static func buildEither(
        second component: Components
    ) -> Components {
        component
    }

    public static func buildArray(
        _ components: [Components]
    ) -> Components {
        Components(names: components.flatMap { $0.names })
    }
}
