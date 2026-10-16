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
        return schema.table(k.table).column(k.paths)
    }

    public var table: SQLable {
        schema.table(T.tableName)
    }

    public func column(_ paths: String...) -> DB.Schema.Table.Column {
        column(paths)
    }

    public func column(_ paths: [String]) -> DB.Schema.Table.Column {
        schema.table(T.tableName).column(paths)
    }

    public func `as`(_ alias: String) -> GenericTableAlias<T> {
        .init(alias, sourceSchema: schema)
    }

    public func inCatalog(_ catalog: DB.Catalog) -> Schema<T> {
        Schema(schema.inCatalog(catalog))
    }
}
