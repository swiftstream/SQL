//
//  CreateSchemaBuilder.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

public class CreateSchemaBuilder<Schema: Schemable>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.root.create.schema
        if shouldCheckIfNotExists {
            query = query.if.not.exists
        }
        query = query[any: Path.Schema(Schema.schemaName)]
        return query.parts
    }
    
    var shouldCheckIfNotExists = false
    
    public init () {}
    
    public func checkIfNotExists() -> Self {
        shouldCheckIfNotExists = true
        return self
    }
}
