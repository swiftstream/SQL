//
//  TableAlias.swift
//  SwifQL
//
//  Created by Mihael Isaev on 11/11/2018.
//

import Foundation


/// Create alias for `Table`
///
/// Usage:
/// * using `TableAlias` for _subquery_
/// ```swift
/// let u = TableAlias("u")
/// let subquery = |SwifQL
///     .select(Fn.count(\User.$id) => "users",
///             \User.$groupID => "groupID")
///     .from(User.table)
///     .groupBy(\User.$groupID)| => u
/// let query = SQL.root.select(..., u.users)
///     .from(...)
///     .join(.left, subquery, on: u.groupID == \Group.$id)
///     .groupBy(..., u.users)
/// ```
@dynamicMemberLookup
public class TableAlias: SQLable {
    public var name: String

    public init (_ name: String) {
        self.name = name
    }
    
    public subscript(dynamicMember path: String) -> SQLable {
        Path.Table(name).column(path)
    }
    
    public var parts: [SQLPart] {
        [SQLPartAlias(name)]
    }
}

protocol AnyGenericTableAlias {
    var alias: String { get }
}

@dynamicMemberLookup
public class GenericTableAlias<M: Decodable>: SQLable, AnyGenericTableAlias {
    public typealias Model = M
    
    public var parts: [SQLPart] {
        [SQLPartTable(schema: nil, table: alias)]
    }
    
    public var table: SQLable {
        SQLableParts(parts: SQLPartTableWithAlias(schema: schema, table: name, alias: alias))
    }
    
    var name: String {
        if let mmm = M.self as? AnyTable.Type {
            return mmm.tableName
        }
        return String(describing: M.self)
    }
    
    var schema: String?
    
    var alias: String
    
    public init(_ alias: String, schema: String?) {
        self.alias = alias
        self.schema = schema ?? (Model.self as? Schemable.Type)?.schemaName
    }
    
    public func column(_ paths: String...) -> Path.TableWithColumn {
        Path.Table(alias).column(paths)
    }
    
    public subscript<V>(dynamicMember keyPath: KeyPath<Model, V>) -> SQLable {
        guard let k = keyPath as? Keypathable else { return "<keyPath should conform to Keypathable>" }
        return Path.Table(alias).column(k.paths)
    }
}

postfix operator *
postfix public func *<T: Decodable>(table: GenericTableAlias<T>) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(SQLPartTable(table.alias))
    parts.append(SQLPartOperator(".*", semanticRole: .starProjection))
    parts.append(o: .space)
    return SQLableParts(parts: parts)
}
postfix public func *(table: AnyTable.Type) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(SQLPartTable(table.tableName))
    parts.append(SQLPartOperator(".*", semanticRole: .starProjection))
    parts.append(o: .space)
    return SQLableParts(parts: parts)
}

//MARK: Decodable extension

extension Decodable {
    public static func `as`(_ alias: String) -> GenericTableAlias<Self> {
        .init(alias, schema: nil)
    }
}

//MARK: AliasedKeyPath

public class AliasedKeyPath<K, T, V> where K: KeyPath<T, V>, T: Table, V: ColumnRepresentable {
    var alias: String
    var kp: K
    init(_ alias: String, _ kp: K) {
        self.alias = alias
        self.kp = kp
    }
}

extension AliasedKeyPath: SQLKeyPathable {
    public var schema: String? { (AModel.self as? Schemable.Type)?.schemaName }
    public var table: String? { alias }
    public var paths: [String] { kp.paths }
}

extension AliasedKeyPath: SQLable {
    public var parts: [SQLPart] {
        if let kp = self.originalKeyPath as? FluentKitFieldable {
            return [SQLPartKeyPath(table: table, paths: [kp.key])]
        }
        return [SQLPartKeyPath(table: table, paths: paths)]
    }
}

extension AliasedKeyPath: SQLUniversalKeyPath, SQLUniversalKeyPathSimple {
    public typealias AType = V
    public typealias AModel = T
    public typealias ARoot = AliasedKeyPath
    
    public var path: String { kp.shortPath }
    public var lastPath: String { kp.lastPath }
    public var originalKeyPath: KeyPath<T, V> { kp }
}