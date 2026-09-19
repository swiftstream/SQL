@resultBuilder
public enum TableDefinitionBuilder {
    public static func buildBlock(
        _ first: any TableDefinition,
        _ rest: any TableDefinition...
    ) -> [any TableDefinition] {
        [first] + rest
    }
}
