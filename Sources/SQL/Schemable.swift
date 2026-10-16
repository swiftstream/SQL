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
    public static func table(_ table: DB.Table) -> DB.Schema.Table {
        (ModelQualification.resolve(Self.self) ?? schema).table(table.name)
    }

    public static func table(_ table: String) -> DB.Schema.Table {
        (ModelQualification.resolve(Self.self) ?? schema).table(table)
    }

    public static func path(_ table: String, _ paths: String...) -> DB.Schema.Table.Column {
        path(table, paths)
    }

    public static func path(_ table: String, _ paths: [String]) -> DB.Schema.Table.Column {
        (ModelQualification.resolve(Self.self) ?? schema).table(table).column(paths)
    }
}
