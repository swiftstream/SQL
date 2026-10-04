//
//  SQLable+Timestamp.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: With

/// SELECT in WITH
/// WITH provides a way to write auxiliary statements for use in a larger query.
/// These statements, which are often referred to as Common Table Expressions or CTEs,
/// can be thought of as defining temporary tables that exist just for one query.
/// Each auxiliary statement in a WITH clause can be a SELECT, INSERT, UPDATE, or DELETE;
/// and the WITH clause itself is attached to a primary statement that can also be a
/// SELECT, INSERT, UPDATE, or DELETE.
/// ```
/// SwifQL
///     .with(.init(Table("Table1"), SQL.root.select(Table("Table2").*).from(Table("Table2"))))
///     .select(Table("Table1").*)
///     .from(Table("Table1"))
/// ```
/// Result
/// ```
/// WITH "Table1" as (SELECT "Table2".* FROM "Table2") SELECT "Table1".* FROM "Table1"
/// ```
/// https://www.postgresql.org/docs/11/queries-with.html
///
extension SQLable {
    public func with(_ withs: With...) -> SQLable {
        with(withs)
    }
    
    public func with(_ withs: [With]) -> SQLable {
        var fragmentParts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.with,
            SQLPartOperator.space
        ]
        for (i, v) in withs.enumerated() {
            if i > 0 {
                fragmentParts.append(o: .comma)
                fragmentParts.append(o: .space)
            }
            fragmentParts.append(contentsOf: v.parts)
        }
        return structurallyAppending(SQLableParts(parts: fragmentParts))
    }
}
