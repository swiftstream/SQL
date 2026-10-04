//
//  CatalogPart.swift
//  SwifQL
//

import Foundation

public struct SQLPartCatalog: SQLPart {
    public let name: String

    public init (_ name: String) {
        self.name = name
    }
}
