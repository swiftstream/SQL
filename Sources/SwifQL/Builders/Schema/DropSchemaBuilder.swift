//
//  DropSchemaBuilder.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

public class DropSchemaBuilder<Schema: Schemable>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.root.drop.schema
        if shouldCheckIfExists {
            query = query.if.exists
        }
        query = query[any: Path.Schema(Schema.schemaName)]
        return query.parts
    }
    
    var shouldCheckIfExists = false
    
    public init () {}
    
    public func checkIfExists() -> Self {
        shouldCheckIfExists = true
        return self
    }
}
