//
//  NullPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 31.10.2020.
//

import Foundation

public var SQLNull: SQLPartNull { .init() }

public struct SQLPartNull: SQLPart, SQLable {
    public var parts: [SQLPart] { [self] }
    public init () {}
}
