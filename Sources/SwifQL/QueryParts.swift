//
//  QueryParts.swift
//  SwifQL
//
//  Created by Mihael Isaev on 18.05.2020.
//

import Foundation

public class QueryParts {
    public var joins: [SQLJoinBuilder] = []
    public var wheres: [SQLable] = []
    public var groupBy: [SQLable] = []
    public var havings: [SQLable] = []
    public var orderBy: [OrderByItem] = []
    public var offset: Int?
    public var limit: Int?
    
    public init () {}
    
    public func copy() -> QueryParts {
        let copy = QueryParts()
        
        copy.joins = joins
        copy.wheres = wheres
        copy.groupBy = groupBy
        copy.havings = havings
        copy.orderBy = orderBy
        copy.offset = offset
        copy.limit = limit
        
        return copy
    }
    
    public func buildQuery() -> SQLable {
        var query: SQLable = SQL.root
        joins.forEach {
            query = _SQLStructuralComposition.appendStatementContents(
                from: $0,
                to: query
            )
        }
        wheres.enumerated().forEach {
            if $0.offset == 0 {
                query = query.where($0.element)
            } else {
                query = query && $0.element
            }
        }
        if groupBy.count > 0 {
            query = query.groupBy(groupBy)
        }
        havings.enumerated().forEach {
            if $0.offset == 0 {
                query = query.having($0.element)
            } else {
                query = query && $0.element
            }
        }
        if orderBy.count > 0 {
            query = query.orderBy(orderBy)
        }
        if let limit = limit {
            query = query.limit(limit)
        }
        if let offset = offset {
            query = query.offset(offset)
        }
        return query
    }
    
    public func appended(to query: SQLable) -> SQLable {
        let q = buildQuery()
        guard q.parts.count > 0 else { return query }
        return _SQLStructuralComposition.appendStatementContents(from: q, to: query)
    }
}
