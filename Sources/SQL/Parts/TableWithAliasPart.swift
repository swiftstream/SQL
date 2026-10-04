//
//  TableWithAliasPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartTableWithAlias: SQLPart {
    public var schema: String?
    public var table, alias: String
    
    public init (schema: String?, table: String, alias: String) {
        self.schema = schema
        self.table = table
        self.alias = alias
    }
}
