//
//  SQLable+Distinct.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: DISTINCT

extension SQLable {
    public var distinct: SQLable {
        return structurallyAppending(SQLableParts(parts: [
            SQLPartOperator.space,
            .distinct,
        ]))
    }
}

