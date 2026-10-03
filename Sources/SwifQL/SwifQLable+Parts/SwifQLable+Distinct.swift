//
//  SwifQLable+Distinct.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: DISTINCT

extension SwifQLable {
    public var distinct: SwifQLable {
        return structurallyAppending(SwifQLableParts(parts: [
            SwifQLPartOperator.space,
            .distinct,
        ]))
    }
}

