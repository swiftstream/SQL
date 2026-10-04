//
//  DatePart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLPartDate: SQLPart {
    public var date: Date
    
    public init (_ date: Date) {
        self.date = date
    }
}
