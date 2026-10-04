//
//  Schemable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

import Foundation

public protocol Schemable {
    /// This schema's unique name. By default, this property is set to a `String` describing the type.
    static var schemaName: String { get }
}

// MARK: Optional

extension Schemable {
    public static var schemaName: String { "public" }
    
    public static func table(_ table: Path.Table) -> Path.SchemaWithTable {
        Path.Schema(schemaName).table(table.name)
    }
    
    public static func table(_ table: String) -> Path.SchemaWithTable {
        Path.Schema(schemaName).table(table)
    }
    
    public static func path(_ table: String, _ paths: String...) -> Path.SchemaWithTableAndColumn {
        path(table, paths)
    }
    
    public static func path(_ table: String, _ paths: [String]) -> Path.SchemaWithTableAndColumn {
        Path.Schema(schemaName).table(table).column(paths)
    }
}
