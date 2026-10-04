//
//  ArrayPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 06.06.2020.
//

import Foundation

public protocol SQLPartArray: SQLPart {
    var elements: [SQLable] { get }
}
