//
//  SQLable+Window.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

import Foundation

//MARK: Window

extension SQLable {
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func window(_ expression: SQLable) -> SQLable {
        let parts: [SQLPart] = [
            SQLPartOperator.space,
            .window,
            .space,
        ] + expression.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func window(_ window: SQLable, as query: SQLable) -> SQLable {
        var parts = window.parts
        parts.append(contentsOf: window.parts)
        parts.append(o: .space)
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket)
        return self.window(SQLableParts(rawParts: parts))
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func window(_ window: SQLable, asPartitionBy expression: SQLable, orderBy: OrderByItem...) -> SQLable {
        self.window(window, asPartitionBy: expression, orderBy: orderBy)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func window(_ window: SQLable, asPartitionBy expression: SQLable, orderBy: [OrderByItem]) -> SQLable {
        var query = SQL.partition(by: expression)
        if orderBy.count > 0 {
            query = query.orderBy(orderBy)
        }
        return self.window(window, as: query)
    }
}
