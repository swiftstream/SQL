//
//  UnsafeValuePart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartUnsafeValue: SQLPart {
    var unsafeValue: Encodable
    
    public init (_ value: Encodable) {
        unsafeValue = value
    }
}
