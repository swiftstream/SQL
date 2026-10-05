//
//  SQLSelectBuilder.swift
//  App
//
//  Created by Mihael Isaev on 22/02/2019.
//

import Foundation

public class SQLSelectBuilder: QueryBuilderable {
    var select: [SQLable] = []
    var froms: [SQLable] = []
    
    public var queryParts = QueryParts()
    
    public init() {}
    
    public func copy() -> SQLSelectBuilder {
        let copy = SQLSelectBuilder()
        
        copy.select = select
        copy.froms = froms
        copy.queryParts = queryParts.copy()
        
        return copy
    }
    
    // MARK: Select
    
    @discardableResult
    public func select(_ item: SQLable...) -> SQLSelectBuilder {
        select(item)
    }
    
    @discardableResult
    public func select(_ items: [SQLable]) -> SQLSelectBuilder {
        select.append(contentsOf: items)
        return self
    }
    
    // MARK: From
    
    @discardableResult
    public func from(_ item: SQLable...) -> SQLSelectBuilder {
        from(item)
    }
    
    @discardableResult
    public func from(_ items: [SQLable]) -> SQLSelectBuilder {
        froms.append(contentsOf: items)
        return self
    }
    
    public func build() -> SQLable {
        var query = SQL.select(select)
        if froms.count > 0 {
            query = query.from(froms)
        }
        return queryParts.appended(to: query)
    }
}
