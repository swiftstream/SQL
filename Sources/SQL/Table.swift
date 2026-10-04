//
//  Tableable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 05/11/2018.
//

import Foundation

public protocol AnyTable: Codable {
    /// This model's unique name. By default, this property is set to a `String` describing the type.
    static var tableName: String { get }
}

extension AnyTable {
    public static var tableName: String {
        String(describing: Self.self)
    }
    
    public static func column(_ paths: String...) -> Path.SchemaWithTableAndColumn {
        Path.Schema((Self.self as? Schemable.Type)?.schemaName).table(tableName).column(paths)
    }
    
    public static func inSchema(_ name: String) -> Schema<Self> {
        .init(name)
    }
    
    public static func inSchema(_ schema: Schemable.Type) -> Schema<Self> {
        .init(schema.schemaName)
    }
}

public protocol KeyPathEncodable {}

@dynamicMemberLookup
public protocol Table: AnyTable, ColumnRoot {
    @_disfavoredOverload
    init ()
    
    static subscript<V>(dynamicMember keyPath: KeyPath<Self, V>) -> SQLable { get }
}

extension Table {
    public static subscript<V>(dynamicMember keyPath: KeyPath<Self, V>) -> SQLable {
        guard let k = keyPath as? Keypathable else { return "<keyPath should conform to Keypathable>" }
        let schema: String? = (Self.self as? Schemable.Type)?.schemaName
        return SQLPartKeyPath(schema: schema, table: Self.tableName, paths: k.paths)
    }
}

public struct ColumnInfo {
    public struct Name {
        public let label, keyPath: String
    }
    public let name: Name
    public let property: AnyColumn
}

extension String {
    fileprivate var withoutLeadingUnderscore: String {
        guard hasPrefix("_") else { return self }
        return String(self.dropFirst())
    }
}

extension Table {
    public var columns: [ColumnInfo] {
        return Mirror(reflecting: self)
            .children
            .compactMap { child in
                guard let property = child.value as? AnyColumn else {
                    return nil
                }
                // remove underscore
                return .init(name: .init(label: property.name, keyPath: child.label?.withoutLeadingUnderscore ?? property.name), property: property)
            }
    }
    
    /// See `Codable`
    
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: TableCodingKey.self)
        try self.columns.forEach {
            let decoder = TableContainerDecoder(container: container, key: .string($0.name.label))
            try $0.property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: TableCodingKey.self)
        for column in columns {
            let key: TableCodingKey
            switch self {
            case _ as KeyPathEncodable:
                key = .string(column.name.keyPath)
            default:
                key = .string(column.name.label)
            }
            let encoder = ContainerEncoder(container: container, key: key)
            try column.property.encode(to: encoder)
        }
    }
}

enum TableCodingKey: CodingKey {
    case string(String)
    case int(Int)
    
    var stringValue: String {
        switch self {
        case .int(let int): return String(describing: int)
        case .string(let string): return string
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let int): return int
        case .string(let string): return Int(string)
        }
    }
    
    init?(stringValue: String) {
        self = .string(stringValue)
    }
    
    init?(intValue: Int) {
        self = .int(intValue)
    }
}

private struct TableContainerDecoder: Decoder, SingleValueDecodingContainer {
    let container: KeyedDecodingContainer<TableCodingKey>
    let key: TableCodingKey
    
    var codingPath: [CodingKey] {
        self.container.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try self.container.nestedContainer(keyedBy: Key.self, forKey: self.key)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try self.container.nestedUnkeyedContainer(forKey: self.key)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try self.container.decode(T.self, forKey: self.key)
    }
    
    func decodeNil() -> Bool {
        do {
            return try self.container.decodeNil(forKey: self.key)
        } catch {
            return true
        }
    }
}

private struct ContainerEncoder: Encoder, SingleValueEncodingContainer {
    var container: KeyedEncodingContainer<TableCodingKey>
    let key: TableCodingKey
    
    var codingPath: [CodingKey] {
        self.container.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        var container = self.container
        return container.nestedContainer(keyedBy: Key.self, forKey: self.key)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = self.container
        return container.nestedUnkeyedContainer(forKey: self.key)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try self.container.encode(value, forKey: self.key)
    }
    
    mutating func encodeNil() throws {
        try self.container.encodeNil(forKey: self.key)
    }
}

extension Table {
    public static func key<Column>(for column: KeyPath<Self, Column>) -> String where Column: ColumnRepresentable {
        Self.init()[keyPath: column].column.name
    }
}