//
//  StringExtensions.swift
//  App
//
//  Created by Mihael Isaev on 06.06.2018.
//

import Foundation

extension String {
    public var singleQuotted: String {
        "'\(self)'"
    }
    
    public var doubleQuotted: String {
        "\"\(self)\""
    }
    
    public var roundBracketted: String {
        "(\(self))"
    }
    
    public static func singleQuotted(_ v: Any) -> String {
        "\(v)".singleQuotted
    }
    
    public static func doubleQuotted(_ v: Any) -> String {
        "\(v)".doubleQuotted
    }
    
    public static func roundBracketted(_ v: Any) -> String {
        "\(v)".roundBracketted
    }
    
    public func `as`(_ v: String) -> String {
        self + " as " + v
    }
}
