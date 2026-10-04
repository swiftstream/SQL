//
//  PostgresJsonObject.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

public typealias PgJsonObject = PostgresJsonObject

public class PostgresJsonObject: SQLable {
    private struct Field {
        enum KeyMode {
            case `default`, keyPath
        }
        let key: SQLable
        let mode: KeyMode
        let value: SQLable
    }
    
    private var fields: [Field] = []
    
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        parts.appendSpaceIfNeeded()
        var body: [SQLPart] = []
        for (i, v) in fields.enumerated() {
            if i > 0 {
                body.append(o: .comma)
                body.append(o: .space)
            }
            switch v.mode {
            case .default:
                body.append(contentsOf: v.key.parts)
            case .keyPath:
                if let key = v.key as? SQLUniversalKeyPathSimple {
                    body.append(o: .custom(key.lastPath.singleQuotted))
                } else {
                    body.append(o: .custom(String(describing: v.key).singleQuotted))
                }
            }
            body.append(o: .comma)
            body.append(o: .space)
            body.append(contentsOf: v.value.parts)
        }
        return Fn.build(.jsonbBuildObject, body: body).parts
    }
    
    public init () {}
    
    public func field(key: SQLable, value: SQLable) -> PostgresJsonObject {
        let field = Field(key: key, mode: .default, value: value)
        fields.append(field)
        return self
    }
    
    public func field(keyPathAsKey: SQLable, value: SQLable) -> PostgresJsonObject {
        let field = Field(key: keyPathAsKey, mode: .keyPath, value: value)
        fields.append(field)
        return self
    }
}
