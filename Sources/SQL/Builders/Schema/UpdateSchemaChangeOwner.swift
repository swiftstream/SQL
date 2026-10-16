//
//  UpdateSchemaChangeOwner.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

public class UpdateSchemaChangeOwner<Schema: Schemable>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.alter.schema
        query = query[any: ModelQualification.resolve(Schema.self)!]
        query = query.owner.to
        query = query[any: DB.Schema(newOwner)]
        return query.parts
    }
    
    var newOwner = ""
    
    public init () {}
    
    public func newOwner(_ name: String) -> Self {
        newOwner = name
        return self
    }
}
