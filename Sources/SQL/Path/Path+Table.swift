//
//  Path+Table.swift
//  SwifQL
//
//  Created by Mihael Isaev on 07.01.2020.
//

import Foundation

extension Path {
    public struct Table {
        public let name: String
        
        public init (_ name: String) {
            self.name = name
        }
        
        @discardableResult
        public func column(_ column: Column) -> TableWithColumn {
            self.column(column.paths)
        }
        
        @discardableResult
        public func column(_ paths: String...) -> TableWithColumn {
            column(paths)
        }
        
        @discardableResult
        public func column(_ paths: [String]) -> TableWithColumn {
            TableWithColumn(table: name, paths: paths)
        }
    }
}

extension Path.Table: SQLable {
    public var parts: [SQLPart] {
        [SQLPartTable(name)]
    }
}

extension Path.Table: KeyPathLastPath {
    public var lastPath: String { "" }
}
