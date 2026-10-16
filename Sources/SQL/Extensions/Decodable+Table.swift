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
        if let schema = ModelQualification.resolve(Self.self) {
            return schema.table(tableName)
        }
        return DB.Table(tableName)
    }
}
