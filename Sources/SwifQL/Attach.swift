//
//  Attach.swift
//  SwifQL
//

import Foundation

/// Controls the optional `ATTACH` modifier.
public enum AttachMode {
    case none
    case ifNotExists
    case orReplace
}

/// A structured `ATTACH` option name and optional value.
///
/// Option names are open to downstream extensions through ``Name``. Values
/// remain ordinary SQLable children so callers can preserve expressions
/// and prepared bindings.
public struct AttachOption: SQLable {
    /// A caller-extensible identity for an `ATTACH` option name.
    public struct Name: Hashable, Sendable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let name: Name
    public let value: SQLable?

    public init(name: Name, value: SQLable? = nil) {
        self.name = name
        self.value = value
    }

    public init(_ name: Name, value: SQLable? = nil) {
        self.init(name: name, value: value)
    }

    public var parts: [SQLPart] {
        var parts: [SQLPart] = [SQLPartOperator.custom(name.rawValue)]
        if let value {
            parts.append(o: .space)
            parts.append(contentsOf: value.parts)
        }
        return parts
    }

    public static var readOnly: Self { Self(name: Name("READ_ONLY")) }

    public static func compress(_ value: SQLable) -> Self {
        Self(name: Name("COMPRESS"), value: value)
    }

    public static func type(_ value: SQLable) -> Self {
        Self(name: Name("TYPE"), value: value)
    }

    public static func defaultTable(_ value: SQLable) -> Self {
        Self(name: Name("DEFAULT_TABLE"), value: value)
    }

    public static func blockSize(_ value: SQLable) -> Self {
        Self(name: Name("BLOCK_SIZE"), value: value)
    }

    public static func rowGroupSize(_ value: SQLable) -> Self {
        Self(name: Name("ROW_GROUP_SIZE"), value: value)
    }

    public static func storageVersion(_ value: SQLable) -> Self {
        Self(name: Name("STORAGE_VERSION"), value: value)
    }

    public static func encryptionKey(_ value: SQLable) -> Self {
        Self(name: Name("ENCRYPTION_KEY"), value: value)
    }

    public static func encryptionCipher(_ value: SQLable) -> Self {
        Self(name: Name("ENCRYPTION_CIPHER"), value: value)
    }

    public static func recoveryMode(_ value: SQLable) -> Self {
        Self(name: Name("RECOVERY_MODE"), value: value)
    }
}

extension SQLable {
    /// Appends `ATTACH` with a parser string-literal source, an optional
    /// structural catalog alias, and ordered structured options.
    public func attach(
        _ source: String,
        mode: AttachMode = .none,
        as catalog: Path.Catalog? = nil,
        options: AttachOption...
    ) -> SQLable {
        attach(source, mode: mode, as: catalog, options: options)
    }

    /// Appends `ATTACH` using a caller-owned option collection.
    public func attach(
        _ source: String,
        mode: AttachMode = .none,
        as catalog: Path.Catalog? = nil,
        options: [AttachOption]
    ) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("ATTACH"))

        switch mode {
        case .none:
            break
        case .ifNotExists:
            parts.append(o: .space, .custom("IF NOT EXISTS"))
        case .orReplace:
            parts.append(o: .space, .custom("OR REPLACE"))
        }

        parts.append(o: .space)
        parts.append(SQLPartSafeValue(source))

        if let catalog {
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(contentsOf: catalog.parts)
        }

        if !options.isEmpty {
            parts.append(o: .space, .openBracket)
            for (index, option) in options.enumerated() {
                if index > 0 {
                    parts.append(o: .comma, .space)
                }
                parts.append(contentsOf: option.parts)
            }
            parts.append(o: .closeBracket)
        }

        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends `DETACH` for a structural catalog name.
    public func detach(_ catalog: Path.Catalog) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("DETACH"), .space)
        parts.append(contentsOf: catalog.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends `USE` for a structural catalog name.
    public func use(_ catalog: Path.Catalog) -> SQLable {
        appendingUse(catalog)
    }

    /// Appends `USE` for a structural schema name.
    public func use(_ schema: Path.Schema) -> SQLable {
        appendingUse(schema)
    }

    /// Appends `USE` for a structural catalog-and-schema path.
    public func use(_ path: Path.CatalogWithSchema) -> SQLable {
        appendingUse(path)
    }

    private func appendingUse(_ target: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("USE"), .space)
        parts.append(contentsOf: target.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
