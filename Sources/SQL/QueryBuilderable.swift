//
//  QueryBuilderable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 18.05.2020.
//

import Foundation

public protocol QueryBuilderable: AnyObject {
    var queryParts: QueryParts { get set }
}

extension QueryBuilderable {
    // MARK: Join
    
    @discardableResult
    public func join(_ mode: JoinMode, _ table: SQLable, on predicates: SQLable) -> Self {
        join(SQLJoinBuilder(mode, table, on: predicates))
    }
    
    @discardableResult
    public func join(_ item: SQLJoinBuilder...) -> Self {
        join(item)
    }
    
    @discardableResult
    public func join(_ items: [SQLJoinBuilder]) -> Self {
        queryParts.joins.append(contentsOf: items)
        return self
    }
    
    // MARK: Where
    
    @discardableResult
    public func `where`(_ item: SQLable...) -> Self {
        `where`(item)
    }
    
    @discardableResult
    public func `where`(_ items: [SQLable]) -> Self {
        queryParts.wheres.append(contentsOf: items)
        return self
    }
    
    // MARK: Group by
    
    @discardableResult
    public func groupBy(_ item: SQLable...) -> Self {
        groupBy(item)
    }
    
    @discardableResult
    public func groupBy(_ items: [SQLable]) -> Self {
        queryParts.groupBy.append(contentsOf: items)
        return self
    }
    
    // MARK: Having
    
    @discardableResult
    public func having(_ item: SQLable...) -> Self {
        having(item)
    }
    
    @discardableResult
    public func having(_ items: [SQLable]) -> Self {
        queryParts.havings.append(contentsOf: items)
        return self
    }
    
    // MARK: Order by
    
    @discardableResult
    public func orderBy(_ item: OrderByItem...) -> Self {
        orderBy(item)
    }
    
    @discardableResult
    public func orderBy(_ items: [OrderByItem]) -> Self {
        queryParts.orderBy.append(contentsOf: items)
        return self
    }
    
    // MARK: Offset
    
    @discardableResult
    public func offset(_ value: Int) -> Self {
        queryParts.offset = value
        return self
    }
    
    // MARK: Limit
    
    @discardableResult
    public func limit(_ value: Int) -> Self {
        queryParts.limit = value
        return self
    }
    @discardableResult
    public func limit(_ offset: Int,_ limit: Int) -> Self {
        queryParts.limit = limit
        queryParts.offset = offset
        return self
    }
}
