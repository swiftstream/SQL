//
//  Prepared.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

public struct SQLPrepared {
    var _dialect: SQLDialect
    var _segments: [SQLPreparedOutputSegment]
    var _values: [Encodable]
    var _formattedValues: [String]
    
    init (
        dialect: SQLDialect,
        segments: [SQLPreparedOutputSegment],
        values: [Encodable],
        formattedValues: [String]
    ) {
        _dialect = dialect
        _segments = segments
        _values = values
        _formattedValues = formattedValues
    }
    
    public var plain: String {
        let formatter = SQLFormatter(_dialect, mode: .plain)
        return formatter.string(from: _segments, with: _formattedValues)
    }
    
    public var splitted: SQLSplittedQuery {
        let formatter = SQLFormatter(_dialect, mode: .binded)
        let result = formatter.string(from: _segments, with: _formattedValues)
        return .init(query: result, values: _values)
    }
}
