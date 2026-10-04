import Foundation

public protocol TableDefinition: SQLable {}

extension NewColumn: TableDefinition {}
extension GeneratedColumn: TableDefinition {}

public struct CreateTable: SQLable {
    public let parts: [SQLPart]

    public init(
        _ table: String,
        schema: String? = nil,
        @TableDefinitionBuilder _ definitions: () -> [any TableDefinition]
    ) {
        let snapshots: [SQLable] = definitions().map {
            SQLableParts(rawParts: $0.parts)
        }
        self.parts = SQL.root.create.table[any: Path.SchemaWithTable(schema: schema, table: table)]
            .tableDefinitions(snapshots)
            .parts
    }
}

extension SQLable {
    /// Appends a parenthesized, comma-separated table-definition list.
    public func tableDefinitions(_ definitions: SQLable...) -> SQLable {
        tableDefinitions(definitions)
    }

    /// Appends a parenthesized, comma-separated table-definition list.
    public func tableDefinitions(_ definitions: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        for (index, definition) in definitions.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: definition.parts)
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
