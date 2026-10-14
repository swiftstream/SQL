//
//  Schemable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

public protocol Schemable {
    static var schema: DB.Schema { get }
}

public protocol Catalogable: Schemable {
    static var catalog: DB.Catalog { get }
}

// MARK: Optional

extension Schemable {
    public static func table(_ table: Path.Table) -> Path.SchemaWithTable {
        Path.Schema(schema.name).table(table.name)
    }

    public static func table(_ table: String) -> Path.SchemaWithTable {
        Path.Schema(schema.name).table(table)
    }

    public static func path(_ table: String, _ paths: String...) -> Path.SchemaWithTableAndColumn {
        path(table, paths)
    }

    public static func path(_ table: String, _ paths: [String]) -> Path.SchemaWithTableAndColumn {
        Path.Schema(schema.name).table(table).column(paths)
    }
}
