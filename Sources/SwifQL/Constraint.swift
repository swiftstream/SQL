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
        var constraint = Constraint(SQL.root.primary.key)
        constraint.isPrimaryKey = true
        return constraint
    }
    
    public static var unique: Constraint {
        .init(SQL.root.unique)
    }
    
    public static var notNull: Constraint {
        var constraint = Constraint(SQL.root.not.null)
        constraint.isNotNull = true
        return constraint
    }
    
    public static func check(name: String? = nil, _ expression: SQLable) -> Constraint {
        var query: SQLable = SQL.root
        if let name = name {
            query = query.constraint[any: Path.Column(name)]
        }
        return .init(query.check.values(expression))
    }
    
    public static func references<T: Table>(_ table: T.Type, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        var schemaName: String?
        if let schemable = table as? Schemable.Type {
            schemaName = schemable.schemaName
        }
        return references(schemaName, table.tableName, onDelete: onDelete, onUpdate: onUpdate)
    }
    
    public static func references(_ schema: String? = nil, _ table: String, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        var query = SQL.root.references[any: Path.SchemaWithTable(schema: schema, table: table)]
        if let action = onDelete {
            query = query.on.delete[any: action]
        }
        if let action = onUpdate {
            query = query.on.update[any: action]
        }
        return .init(query)
    }
}
