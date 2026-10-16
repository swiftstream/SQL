//
//  Constraint.swift
//  SwifQL
//
//  Created by Mihael Isaev on 19.04.2020.
//

import Foundation

public struct Constraint {
    let query: SQLable
    
    init (_ query: SQLable) {
        self.query = query
    }
    
    var isPrimaryKey = false
    var isNotNull = false
    
    public static var primaryKey: Constraint {
        var constraint = Constraint(SQL.primary.key)
        constraint.isPrimaryKey = true
        return constraint
    }
    
    public static var unique: Constraint {
        .init(SQL.unique)
    }
    
    public static var notNull: Constraint {
        var constraint = Constraint(SQL.not.null)
        constraint.isNotNull = true
        return constraint
    }
    
    public static func check(name: String? = nil, _ expression: SQLable) -> Constraint {
        var query: SQLable = SQL
        if let name = name {
            query = query.constraint[any: DB.Column(name)]
        }
        return .init(query.check.values(expression))
    }
    
    public static func references<T: Table>(_ table: T.Type, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        let relation: SQLable
        if let schema = ModelQualification.resolve(table) {
            relation = schema.table(table.tableName)
        } else {
            relation = DB.Table(table.tableName)
        }
        var query = SQL.references[any: relation]
        if let action = onDelete {
            query = query.on.delete[any: action]
        }
        if let action = onUpdate {
            query = query.on.update[any: action]
        }
        return .init(query)
    }
    
    public static func references(_ schema: String? = nil, _ table: String, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        let relation: SQLable
        if let schema {
            relation = DB.Schema(schema).table(table)
        } else {
            relation = DB.Table(table)
        }
        var query = SQL.references[any: relation]
        if let action = onDelete {
            query = query.on.delete[any: action]
        }
        if let action = onUpdate {
            query = query.on.update[any: action]
        }
        return .init(query)
    }
}
