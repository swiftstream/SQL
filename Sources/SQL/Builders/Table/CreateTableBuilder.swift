//
//  CreateTableBuilder.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

public class CreateTableBuilder<T: Table>: SQLable {
    public var parts: [SQLPart] {
        var query = SQL.create.table
        if shouldCheckIfNotExists {
            query = query.if.not.exists
        }
        let table = Path.Schema(schemaName).table(T.tableName)
        query = query[any: table].newColumns(columns)
        return query.parts
    }
    
    var columns: [NewColumn] = []
    var shouldCheckIfNotExists = false
    var schemaName: String?
    
    public init (schema: Schemable.Type? = nil) {
        self.schemaName = schema?.schemaName ?? (T.self as? Schemable.Type)?.schemaName
    }
    
    public init (schema: String) {
        self.schemaName = schema
    }
    
    public func column(_ newColumn: NewColumn) -> Self {
        columns.append(newColumn)
        return self
    }
    
    // MARK: KeyPath
    
    public func column<V>(_ keyPath: KeyPath<T, V>, _ type: Type) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: nil, constraints: [])
    }
    
    public func column<V>(_ keyPath: KeyPath<T, V>, _ type: Type, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: nil, constraints: constraints)
    }
    
    public func column<V>(_ keyPath: KeyPath<T, V>, _ type: Type, _ `default`: ColumnDefault, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: `default`, constraints: constraints)
    }
    
    public func column<V>(_ keyPath: KeyPath<T, V>, type: Type, `default`: ColumnDefault?, constraints: [Constraint]) -> Self where V: ColumnRepresentable {
        column(T.key(for: keyPath), type: type, default: `default`, constraints: constraints)
    }
    
    // MARK: String
    
    public func column(_ name: String, _ type: Type) -> Self {
        column(name, type: type, default: nil, constraints: [])
    }
    
    public func column(_ name: String, _ type: Type, _ constraints: Constraint...) -> Self {
        column(name, type: type, default: nil, constraints: constraints)
    }
    
    public func column(_ name: String, _ type: Type, _ `default`: ColumnDefault, _ constraints: Constraint...) -> Self {
        column(name, type: type, default: `default`, constraints: constraints)
    }
    
    public func column(_ name: String, type: Type, `default`: ColumnDefault?, constraints: [Constraint]) -> Self {
        let newColumn = NewColumn(name, type)
        if let expression = `default`?.query {
            newColumn.default(expression: expression)
        }
        constraints.forEach {
            newColumn.constraint(expression: $0.query)
        }
        columns.append(newColumn)
        return self
    }
    
    public func checkIfNotExists() -> Self {
        shouldCheckIfNotExists = true
        return self
    }
}
