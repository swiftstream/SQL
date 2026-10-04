//
//  Path+SchemaWithTable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

extension Path {
    public struct SchemaWithTable {
        public let schema: String?
        public let table: String
        
        public init (schema: String?, table: String) {
            self.schema = schema
            self.table = table
        }
        
        @discardableResult
        public func column(_ column: Column) -> SchemaWithTableAndColumn {
            self.column(column.paths)
        }
        
        @discardableResult
        public func column(_ paths: String...) -> SchemaWithTableAndColumn {
            column(paths)
        }
        
        @discardableResult
        public func column(_ paths: [String]) -> SchemaWithTableAndColumn {
            SchemaWithTableAndColumn(schema: schema, table: table, paths: paths)
        }
    }
}

extension Path.SchemaWithTable: SQLable {
    public var parts: [SQLPart] {
        [SQLPartTable(schema: schema, table: table)]
    }
}
