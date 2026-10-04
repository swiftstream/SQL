//
//  Decodable+Table.swift
//  
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

extension Decodable {
    public static var table: SQLable {
        let tableName: String
        if let model = Self.self as? AnyTable.Type {
            tableName = model.tableName
        } else {
            tableName = String(describing: Self.self)
        }
        if let schema = Self.self as? Schemable.Type {
            return Path.SchemaWithTable(schema: schema.schemaName, table: tableName)
        } else {
            return Path.Table(tableName)
        }
    }
}
