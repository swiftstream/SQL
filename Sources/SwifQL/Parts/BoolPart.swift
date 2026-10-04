//
//  BoolPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public typealias SQLBool = SQLPartBool

public struct SQLPartBool: SQLPart, SQLable {
    public var parts: [SQLPart] { [self] }
    
    let value: Bool
    
    public init (_ value: Bool) {
        self.value = value
    }
}
