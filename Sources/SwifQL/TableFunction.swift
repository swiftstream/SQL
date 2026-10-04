//
//  TableFunction.swift
//  SwifQL
//

import Foundation

/// A structured, caller-extensible table-function named parameter.
public struct TableFunctionOption: SQLable {
    /// An open identity for a native table-function parameter name.
    public struct Name: Hashable, Sendable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let name: Name
    public let value: SQLable

    public init(name: Name, value: SQLable) {
        self.name = name
        self.value = value
    }

    public init(_ name: Name, value: SQLable) {
        self.init(name: name, value: value)
    }

    public var parts: [SQLPart] {
        var parts: [SQLPart] = [SQLPartOperator.custom(name.rawValue)]
        parts.append(o: .space, .equal, .space)
        parts.append(contentsOf: value.parts)
        return parts
    }

    public static func header(_ value: SQLable) -> Self {
        Self(name: Name("header"), value: value)
    }

    public static func header(_ value: Bool) -> Self {
        header(SQLBool(value))
    }

    public static func delimiter(_ value: SQLable) -> Self {
        Self(name: Name("delim"), value: value)
    }

    public static func sampleSize(_ value: SQLable) -> Self {
        Self(name: Name("sample_size"), value: value)
    }

    public static func unionByName(_ value: SQLable) -> Self {
        Self(name: Name("union_by_name"), value: value)
    }

    public static func unionByName(_ value: Bool) -> Self {
        unionByName(SQLBool(value))
    }

    public static func filename(_ value: SQLable) -> Self {
        Self(name: Name("filename"), value: value)
    }

    public static func filename(_ value: Bool) -> Self {
        filename(SQLBool(value))
    }

    public static func hivePartitioning(_ value: SQLable) -> Self {
        Self(name: Name("hive_partitioning"), value: value)
    }

    public static func hivePartitioning(_ value: Bool) -> Self {
        hivePartitioning(SQLBool(value))
    }

    public static func format(_ value: SQLable) -> Self {
        Self(name: Name("format"), value: value)
    }
}