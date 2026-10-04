//
//  Alias.swift
//  SwifQL
//
//  Created by Mihael Isaev on 19.04.2020.
//

import Foundation

public protocol AnyAlias {
    var name: String { get }
    var inputValue: Encodable? { get }
    var isChanged: Bool { get }
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

public protocol AliasRepresentable {
    associatedtype Value: Codable
    var alias: Alias<Value> { get }
}

@propertyWrapper
public final class Alias<Value>: AnyAlias, AliasRepresentable, ColumnRootNameable, Encodable where Value: Codable {
    public let name: String
    
    var outputValue: Value?
    public internal(set) var inputValue: Encodable?
    public var isChanged: Bool = false
    
    public var alias: Alias<Value> { self }
    public var columnName: String { alias.name }
    
    public var projectedValue: Alias<Value> { self }
    
    public var wrappedValue: Value {
        get {
            if let value = self.inputValue {
                return value as! Value
            } else if let value = self.outputValue {
                return value
            } else {
                fatalError("Cannot access field before it is initialized")
            }
        }
        set {
            self.inputValue = newValue
            self.isChanged = true
        }
    }
    
    public init(_ name: String) {
        self.name = name
    }
    
    /// See `Codable`
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? _Optional.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType._none as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
        self.isChanged = false
    }
}

protocol _Optional {
    static var _none: Any { get }
}

extension Optional: _Optional {
    static var _none: Any {
        return Self.none as Any
    }
}

// MARK: - KeyPath

protocol _AliasKeyPath {}

extension KeyPath: _AliasKeyPath where Value: AnyAlias {}

extension KeyPath: SQLable, CustomStringConvertible where Root: ColumnRoot, Value: ColumnRootNameable {
    public var parts: [SQLPart] {
        if let kp = self as? Keypathable {
            return Path.Schema(kp.schema).table(kp.table).column(Root.key(for: self)).parts
        }
        return [SQLPartAlias(Root.key(for: self))]
    }
}

extension KeyPath: RowField where Root: ColumnRoot, Value: ColumnRootNameable {}

// MARK: - Aliasable

public protocol Aliasable: ColumnRoot, Codable {
    init ()
}

extension Aliasable {
    var columns: [(String, AnyAlias)] {
        return Mirror(reflecting: self)
            .children
            .compactMap { child in
                guard let property = child.value as? AnyAlias else {
                    return nil
                }
                // remove underscore
                return (property.name, property)
            }
    }
    
    /// See `Codable`
    
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: AliasCodingKey.self)
        try self.columns.forEach { label, property in
            let decoder = AliasContainerDecoder(container: container, key: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: AliasCodingKey.self)
        try self.columns.forEach { label, property in
            let encoder = ContainerEncoder(container: container, key: .string(label))
            try property.encode(to: encoder)
        }
    }
}

enum AliasCodingKey: CodingKey {
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

private struct AliasContainerDecoder: Decoder, SingleValueDecodingContainer {
    let container: KeyedDecodingContainer<AliasCodingKey>
    let key: AliasCodingKey
    
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
    var container: KeyedEncodingContainer<AliasCodingKey>
    let key: AliasCodingKey
    
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
