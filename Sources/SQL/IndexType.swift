//
//  IndexType.swift
//  SwifQL
//
//  Created by Mihael Isaev on 18.08.2020.
//

import Foundation

public class IndexType: SQLable {
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        parts.append(o: .custom(name))
        return parts
    }
    
    let name: String
    
    public init (name: String) {
        self.name = name
    }
    
    public static var btree: IndexType {
        .init(name: "BTREE")
    }
    
    public static var hash: IndexType {
        .init(name: "HASH")
    }
    
    public static var gist: IndexType {
        .init(name: "GIST")
    }
    
    public static var gin: IndexType {
        .init(name: "GIN")
    }
    
    public static var spgist: IndexType {
        .init(name: "SPGIST")
    }
    
    public static var brin: IndexType {
        .init(name: "BRIN")
    }

    public static var art: IndexType {
        .init(name: "ART")
    }
}
