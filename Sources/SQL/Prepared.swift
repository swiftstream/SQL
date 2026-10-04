//
//  Prepared.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

public struct SQLPrepared {
    var _dialect: SQLDialect
    var _query: String
    var _values: [Encodable]
    var _formattedValues: [String]
    
    init (dialect: SQLDialect, query: String, values: [Encodable], formattedValues: [String]) {
        _dialect = dialect
        _query = query
        _values = values
        _formattedValues = formattedValues
    }
    
    public var plain: String {
        guard _values.count > 0 else { return _query }
        let formatter = SQLFormatter(_dialect, mode: .plain)
        return formatter.string(from: _query, with: _formattedValues)
    }
    
    public var splitted: SQLSplittedQuery {
        guard _values.count > 0 else { return .init(query: _query, values: _values) }
        let formatter = SQLFormatter(_dialect, mode: .binded)
        let result = formatter.string(from: _query, with: _formattedValues)
        return .init(query: result, values: _values)
    }
}
