//
//  AliasPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartAlias: SQLPart {
    var alias: String
    
    init (_ alias: String) {
        self.alias = alias
    }
}
