//
//  FormattedKeyPath.swift
//  SwifQL
//
//  Created by Mihael Isaev on 20/06/2019.
//

import Foundation

/// Formatting keypath
public typealias FKP = FormattedKeyPath

public struct FormattedKeyPath {
    let _table: String
    let _schema: DB.Schema?
    let _paths: [String]

    init(table: String, schema: DB.Schema?, paths: [String]) {
        _table = table
        _schema = schema
        _paths = paths
    }
    
    public init <T: Table>(_ table: T.Type, _ paths: String...) {
        self.init(table: table.tableName, schema: ModelQualification.resolve(T.self), paths: paths)
    }
    
    public init <T: Table>(_ table: T.Type, _ paths: [String]) {
        self.init(table: table.tableName, schema: ModelQualification.resolve(T.self), paths: paths)
    }
    
    public init (_ table: String, _ paths: String...) {
        self.init(table: table, schema: nil, paths: paths)
    }
    
    public init (_ table: String, _ paths: [String]) {
        self.init(table: table, schema: nil, paths: paths)
    }
}

extension FormattedKeyPath: SQLable {
    public var parts: [SQLPart] {
        [SQLPartKeyPath(
            catalog: _schema?.catalog?.name,
            schema: _schema?.name,
            table: _table,
            paths: _paths
        )]
    }
}

extension FormattedKeyPath: KeyPathLastPath {
    public var lastPath: String { _paths.last ?? "" }
}

extension Table {
    /// Manual key path. Alias to `\User.something`
    public static func manualKeyPath(_ paths: String...) -> FormattedKeyPath {
        manualKeyPath(paths)
    }
    
    /// Manual key path. Alias to `\User.something`
    public static func manualKeyPath(_ paths: [String]) -> FormattedKeyPath {
        FormattedKeyPath(table: tableName, schema: ModelQualification.resolve(Self.self), paths: paths)
    }
    
    /// Manual key path. Alias to `\User.something`
    public static func mkp(_ paths: String...) -> FormattedKeyPath {
        manualKeyPath(paths)
    }
    
    /// Manual key path. Alias to `\User.something`
    public static func mkp(_ paths: [String]) -> FormattedKeyPath {
        manualKeyPath(paths)
    }
}
