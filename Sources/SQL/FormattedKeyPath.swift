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
    let _paths: [String]
    
    public init <T: Table>(_ table: T.Type, _ paths: String...) {
        _table = table.tableName
        _paths = paths
    }
    
    public init <T: Table>(_ table: T.Type, _ paths: [String]) {
        _table = table.tableName
        _paths = paths
    }
    
    public init (_ table: String, _ paths: String...) {
        _table = table
        _paths = paths
    }
    
    public init (_ table: String, _ paths: [String]) {
        _table = table
        _paths = paths
    }
}

extension FormattedKeyPath: SQLable {
    public var parts: [SQLPart] {
        [SQLPartKeyPath(table: _table, paths: _paths)]
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
        FormattedKeyPath(tableName, paths)
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
