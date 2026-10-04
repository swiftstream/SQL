//
//  SafeValuePart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartSafeValue: SQLPart {
    var safeValue: Any?
    
    public init (_ value: Any?) {
        safeValue = value
    }
}
