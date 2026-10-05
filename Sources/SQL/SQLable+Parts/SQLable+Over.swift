//
//  SQLable+Over.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

import Foundation

//MARK: Over

extension SQLable {
    public var over: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .over)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(_ query: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .over)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(partitionBy partition_expression: SQLable, orderBy: OrderByItem...) -> SQLable {
        over(partitionBy: partition_expression, orderBy: orderBy)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(partitionBy partition_expression: SQLable, orderBy: [OrderByItem]) -> SQLable {
        var query = SQL.partition(by: partition_expression)
        if orderBy.count > 0 {
            query = query.orderBy(orderBy)
        }
        return over(query)
    }
}
