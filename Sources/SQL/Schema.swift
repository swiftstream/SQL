//
//  Schema.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

@dynamicMemberLookup
public struct Schema<T: AnyTable> {
    let schema: DB.Schema

    public init(_ name: String) {
        self.schema = DB.Schema(name)
    }

    @_disfavoredOverload
    public init(_ schema: DB.Schema) {
        self.schema = schema
    }

    public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> SQLable {
        guard let k = keyPath as? Keypathable else { return "<keyPath should conform to Keypathable>" }
        return SQLPartKeyPath(schema: schema.name, table: k.table, paths: k.paths)
    }

    public var table: SQLable {
        Path.SchemaWithTable(schema: schema.name, table: T.tableName)
    }

    public func column(_ paths: String...) -> Path.SchemaWithTableAndColumn {
        column(paths)
    }

    public func column(_ paths: [String]) -> Path.SchemaWithTableAndColumn {
        .init(schema: schema.name, table: T.tableName, paths: paths)
    }

    public func `as`(_ alias: String) -> GenericTableAlias<T> {
        .init(alias, schema: schema.name)
    }

    public func inCatalog(_ catalog: DB.Catalog) -> Schema<T> {
        Schema(schema.inCatalog(catalog))
    }
}
