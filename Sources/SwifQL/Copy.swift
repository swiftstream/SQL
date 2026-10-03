//
//  Copy.swift
//  SwifQL
//

import Foundation

/// A structured, caller-extensible `COPY` option.
public struct CopyOption: SwifQLable {
    /// An open identity for a native `COPY` option name.
    public struct Name: Hashable, Sendable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let name: Name
    public let value: SwifQLable?

    public init(name: Name, value: SwifQLable? = nil) {
        self.name = name
        self.value = value
    }

    public init(_ name: Name, value: SwifQLable? = nil) {
        self.init(name: name, value: value)
    }

    public var parts: [SwifQLPart] {
        var parts: [SwifQLPart] = [SwifQLPartOperator.custom(name.rawValue)]
        if let value {
            parts.append(o: .space)
            parts.append(contentsOf: value.parts)
        }
        return parts
    }

    public static func format(_ value: SwifQLable) -> Self {
        Self(name: Name("FORMAT"), value: value)
    }

    public static var header: Self { Self(name: Name("HEADER")) }

    public static func header(_ value: SwifQLable) -> Self {
        Self(name: Name("HEADER"), value: value)
    }

    public static func header(_ value: Bool) -> Self {
        header(SwifQLBool(value))
    }

    public static func delimiter(_ value: SwifQLable) -> Self {
        Self(name: Name("DELIMITER"), value: value)
    }

    public static func compression(_ value: SwifQLable) -> Self {
        Self(name: Name("COMPRESSION"), value: value)
    }

    public static func null(_ value: SwifQLable) -> Self {
        Self(name: Name("NULL"), value: value)
    }

    public static var array: Self { Self(name: Name("ARRAY")) }

    public static func array(_ value: SwifQLable) -> Self {
        Self(name: Name("ARRAY"), value: value)
    }

    public static func array(_ value: Bool) -> Self {
        array(SwifQLBool(value))
    }

    public static func rowGroupSize(_ value: SwifQLable) -> Self {
        Self(name: Name("ROW_GROUP_SIZE"), value: value)
    }

    public static func compressionLevel(_ value: SwifQLable) -> Self {
        Self(name: Name("COMPRESSION_LEVEL"), value: value)
    }

    public static var schema: Self { Self(name: Name("SCHEMA")) }
}

private func appendCopyOptions(_ options: [CopyOption], to parts: inout [SwifQLPart]) {
    guard !options.isEmpty else { return }

    parts.append(o: .space, .openBracket)
    for (index, option) in options.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(contentsOf: option.parts)
    }
    parts.append(o: .closeBracket)
}

extension SwifQLable {
    /// Copies a structural table to an ordinary destination expression.
    public func copy(
        _ table: Path.Table,
        to destination: SwifQLable,
        options: CopyOption...
    ) -> SwifQLable {
        copy(table, to: destination, options: options)
    }

    /// Copies a structural table to an ordinary destination expression using
    /// a caller-owned ordered option collection.
    public func copy(
        _ table: Path.Table,
        to destination: SwifQLable,
        options: [CopyOption]
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("COPY"), .space)
        parts.append(contentsOf: table.parts)
        parts.append(o: .space, .to, .space)
        parts.append(contentsOf: destination.parts)
        appendCopyOptions(options, to: &parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Copies an ordinary source expression into a structural table. The
    /// parenthesized source is stable for literal, prepared, and expression
    /// forms and is intentionally independent of preparation mode.
    public func copy(
        _ table: Path.Table,
        from source: SwifQLable,
        options: CopyOption...
    ) -> SwifQLable {
        copy(table, from: source, options: options)
    }

    /// Copies an ordinary source expression into a structural table using a
    /// caller-owned ordered option collection.
    public func copy(
        _ table: Path.Table,
        from source: SwifQLable,
        options: [CopyOption]
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("COPY"), .space)
        parts.append(contentsOf: table.parts)
        parts.append(o: .space, .from, .space, .openBracket)
        parts.append(contentsOf: source.parts)
        parts.append(o: .closeBracket)
        appendCopyOptions(options, to: &parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Copies a parenthesized query result to an ordinary destination
    /// expression.
    public func copy(
        query: SwifQLable,
        to destination: SwifQLable,
        options: CopyOption...
    ) -> SwifQLable {
        copy(query: query, to: destination, options: options)
    }

    /// Copies a parenthesized query result to an ordinary destination
    /// expression using a caller-owned ordered option collection.
    public func copy(
        query: SwifQLable,
        to destination: SwifQLable,
        options: [CopyOption]
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("COPY"), .space, .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket, .space, .to, .space)
        parts.append(contentsOf: destination.parts)
        appendCopyOptions(options, to: &parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Copies all objects or one schema from a structural source catalog to a
    /// structural destination catalog.
    public func copy(
        fromDatabase source: Path.Catalog,
        to destination: Path.Catalog,
        options: CopyOption...
    ) -> SwifQLable {
        copy(fromDatabase: source, to: destination, options: options)
    }

    /// Copies database objects using a caller-owned ordered option collection.
    public func copy(
        fromDatabase source: Path.Catalog,
        to destination: Path.Catalog,
        options: [CopyOption]
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("COPY"), .space, .custom("FROM DATABASE"), .space)
        parts.append(contentsOf: source.parts)
        parts.append(o: .space, .to, .space)
        parts.append(contentsOf: destination.parts)
        appendCopyOptions(options, to: &parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
