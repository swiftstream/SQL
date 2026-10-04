//
//  Codable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 25.04.2020.
//

import Foundation

public protocol SQLCodable: Codable, SQLable {}

extension SQLCodable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}

public protocol SQLEncodable: Encodable, SQLable {}

extension SQLEncodable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}

extension Array: SQLCodable where Element: SQLCodable {}
