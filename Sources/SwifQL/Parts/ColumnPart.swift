//
//  ColumnPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartColumn: SQLPart {
    public var name: String
    
    public init (_ name: String) {
        self.name = name
    }
}
