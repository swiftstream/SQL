//
//  SwifQLable+Over.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

import Foundation

//MARK: Over

extension SwifQLable {
    public var over: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .over)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(_ query: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .over)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(partitionBy partition_expression: SwifQLable, orderBy: OrderByItem...) -> SwifQLable {
        over(partitionBy: partition_expression, orderBy: orderBy)
    }
    
    /// [Learn more →](https://www.postgresqltutorial.com/postgresql-window-function/)
    public func over(partitionBy partition_expression: SwifQLable, orderBy: [OrderByItem]) -> SwifQLable {
        var query = SwifQL.partition(by: partition_expression)
        if orderBy.count > 0 {
            query = query.orderBy(orderBy)
        }
        return over(query)
    }
}
