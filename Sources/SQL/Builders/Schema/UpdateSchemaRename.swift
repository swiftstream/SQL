//
//  UpdateSchemaRename.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12.04.2020.
//

public class UpdateSchemaRenameBuilder<Schema: Schemable>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.alter.schema
        query = query[any: ModelQualification.resolve(Schema.self)!]
        query = query.rename.to
        query = query[any: DB.Schema(newName)]
        return query.parts
    }
    
    var newName = ""
    
    public init () {}
    
    public func newName(_ name: String) -> Self {
        newName = name
        return self
    }
}
