//
//  Enum.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public protocol AnySQLEnum: Codable, SQLable {
    static var name: String { get }
    var anyRawValue: Any { get }
}

protocol AnySQLEnumArray {
    var items: [AnySQLEnum] { get }
}

extension Array: AnySQLEnumArray where Element: AnySQLEnum {
    var items: [AnySQLEnum] { self }
}

public protocol SQLEnum: AnySQLEnum, RawRepresentable, CaseIterable {
    static var name: String { get }
}

extension SQLEnum {
    public static var name: String { String(describing: Self.self).lowercased() }
    public var anyRawValue: Any { rawValue }
}

/// See `SQLable`
extension SQLEnum {
    public var parts: [SQLPart] { [SQLPartSafeValue(rawValue)] }
}

/// Allows to compare enum with enum column
///
/// Usage:
/// 
/// ```swift
/// \User.$status == UserStatus.banned
/// ```
public func == <A, B>(lhs: KeyPath<A, B>, rhs: B.Value.RawValue) -> SQLable
    where A: Table, B: ColumnRepresentable, B: ColumnRootNameable, B.Value: SQLEnum {
    SQLPredicate(operator: .equal, lhs: lhs, rhs: SQLableParts(parts: SQLPartSafeValue(rhs)))
}
