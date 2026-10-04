//
//  Path+SchemaWithTableAndColumn.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

extension Path {
    public struct SchemaWithTableAndColumn {
        let schema: String?
        let table: String
        let paths: [String]
    }
}

extension Path.SchemaWithTableAndColumn: SQLable {
    public var parts: [SQLPart] {
        [SQLPartKeyPath(schema: schema, table: table, paths: paths)]
    }
}

extension Path.SchemaWithTableAndColumn: KeyPathLastPath {
    public var lastPath: String { paths.last ?? "" }
}
