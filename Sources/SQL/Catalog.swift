@dynamicMemberLookup
public struct Catalog<T: AnyTable> {
    let catalog: DB.Catalog

    public init(_ catalog: DB.Catalog) {
        self.catalog = catalog
    }

    public func inSchema(_ schema: DB.Schema) -> Schema<T> {
        Schema<T>(schema.inCatalog(catalog))
    }
}

extension Catalog where T: Schemable {
    var normalizedSchema: DB.Schema {
        T.schema.inCatalog(catalog)
    }

    public var table: SQLable {
        normalizedSchema.table(T.tableName)
    }
}

extension Catalog where T: Table & Schemable {
    public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> SQLable {
        guard let key = keyPath as? Keypathable else { return "<keyPath should conform to Keypathable>" }
        return normalizedSchema.table(key.table).column(key.paths)
    }
}

extension AnyTable {
    public static func inCatalog(_ catalog: DB.Catalog) -> Catalog<Self> {
        Catalog(catalog)
    }
}
