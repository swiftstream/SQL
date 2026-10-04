//
//  Keypathable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 11/11/2018.
//

import Foundation

public protocol Keypathable: KeyPathLastPath {
    var schema: String? { get }
    var table: String { get }
    var paths: [String] { get }
    var shortPath: String { get }
    var lastPath: String { get }
}

extension KeyPath: KeyPathLastPath where Root: Table, Value: ColumnRepresentable {
    public var lastPath: String {
        Root.key(for: self)
    }
}

extension KeyPath: Keypathable where Root: Table, Value: ColumnRepresentable {
    public var schema: String? {
        (Root.self as? Schemable.Type)?.schemaName
    }
    
    public var table: String {
        Root.tableName
    }
    
    public var paths: [String] {
        [Root.key(for: self)]
    }
    
    public var shortPath: String {
        Root.key(for: self)
    }
}
