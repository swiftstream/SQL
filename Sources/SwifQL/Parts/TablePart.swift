//
//  TablePart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartSchema: SQLPart {
    public var schema: String?
    public init (_ schema: String?) {
        self.schema = schema
    }
}

public struct SQLPartTable: SQLPart {
    public var schema: String?
    public var table: String
    public init (_ table: String) {
        self.table = table
    }
    public init (schema: String?, table: String) {
        self.schema = schema
        self.table = table
    }
}
