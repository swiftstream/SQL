@resultBuilder
public enum AlterTableActionBuilder {
    public static func buildBlock(
        _ first: any AlterTableAction,
        _ rest: any AlterTableAction...
    ) -> [any AlterTableAction] {
        [first] + rest
    }
}
