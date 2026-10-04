//
//  Path+Schema.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

extension Path {
    public struct Schema {
        public let name: String?
        
        public init (_ name: String?) {
            self.name = name
        }
        
        @discardableResult
        public func table(_ table: Table) -> SchemaWithTable {
            self.table(table.name)
        }
        
        @discardableResult
        public func table(_ table: String) -> SchemaWithTable {
            .init(schema: name, table: table)
        }
    }
}

extension Path.Schema: SQLable {
    public var parts: [SQLPart] {
        [SQLPartSchema(name)]
    }
}

extension Path.Schema: KeyPathLastPath {
    public var lastPath: String { "" }
}
