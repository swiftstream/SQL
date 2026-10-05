//
//  DropTableBuilder.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

public class DropTableBuilder<T: Table>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.drop.table
        if shouldCheckIfExists {
            query = query.if.exists
        }
        query = query[any: Path.Table(T.tableName)]
        return query.parts
    }
    
    var shouldCheckIfExists = false
    
    public init () {}
    
    public func checkIfExists() -> Self {
        shouldCheckIfExists = true
        return self
    }
}
