//
//  Types+Nested.swift
//  SwifQL
//

import Foundation

private func quotedNestedTypeMember(_ name: String) -> String {
    let escaped = name.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
}

extension TypeStructure {
    /// The historical textual spelling retained for raw compatibility. The
    /// renderer consumes `TypeStructure` directly through `SQLPartType`.
    internal var legacyName: String {
        switch self {
        case let .collection(constructor, element, length):
            if constructor == .list {
                return "\(element.name)[]"
            }
            if constructor == .array, let length {
                return "\(element.name)[\(length)]"
            }
            if let length {
                return "\(constructor.name)(\(element.name), \(length))"
            }
            return "\(constructor.name)(\(element.name))"
        case let .map(constructor, key, value):
            return "\(constructor.name.uppercased())(\(key.name), \(value.name))"
        case let .members(constructor, members):
            let body = members.map { member in
                "\(quotedNestedTypeMember(member.name)) \(member.type.name)"
            }.joined(separator: ", ")
            return "\(constructor.name.uppercased())(\(body))"
        }
    }
}

extension Type {
    /// Variable-length LIST type.
    public static func list(_ element: Type) -> Type {
        .init(structure: .collection(.list, element: element, length: nil))
    }

    /// Fixed-size ARRAY type.
    public static func array(_ element: Type, length: Int) -> Type {
        precondition(length > 0, "Fixed ARRAY length must be greater than zero")
        return .init(structure: .collection(.array, element: element, length: length))
    }

    /// MAP type with the supplied key and value types.
    public static func map(key: Type, value: Type) -> Type {
        .init(structure: .map(.map, key: key, value: value))
    }

    /// STRUCT type with named members.
    public static func `struct`(_ members: (String, Type)...) -> Type {
        `struct`(members)
    }

    /// STRUCT type with named members.
    public static func `struct`(_ members: [(String, Type)]) -> Type {
        .init(
            structure: .members(
                .struct,
                members.map { TypeMember($0.0, $0.1) }
            )
        )
    }

    /// UNION type with named members.
    public static func union(_ members: (String, Type)...) -> Type {
        union(members)
    }

    /// UNION type with named members.
    public static func union(_ members: [(String, Type)]) -> Type {
        .init(
            structure: .members(
                .union,
                members.map { TypeMember($0.0, $0.1) }
            )
        )
    }
}