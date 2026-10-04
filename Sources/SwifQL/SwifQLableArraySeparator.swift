//
//  SQLableArraySeparator.swift
//  
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

public enum SQLableArraySeparator {
    case comma
    
    var `operator`: SQLPartOperator {
        switch self {
        case .comma: return .comma
        }
    }
}