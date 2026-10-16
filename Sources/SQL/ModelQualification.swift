/// Resolves model-backed schema capability into one normalized SQL scope.
enum ModelQualification {
    static func resolve(_ type: Any.Type) -> DB.Schema? {
        if let catalogable = type as? Catalogable.Type {
            return catalogable.schema.inCatalog(catalogable.catalog)
        }
        if let schemable = type as? Schemable.Type {
            return schemable.schema
        }
        return nil
    }
}
