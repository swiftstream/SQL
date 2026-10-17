//
//  Formatter.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

struct SQLFormatter {
    private let dialect: SQLDialect
    private let mode: Mode
    
    init (_ dialect: SQLDialect, mode: Mode) {
        self.dialect = dialect
        self.mode = mode
    }
    
    enum Mode {
        case binded
        case plain
    }
    
    func string(from segments: [SQLPreparedOutputSegment], with formattedValues: [String]) -> String {
        var output: [String] = []
        output.reserveCapacity(segments.count)
        var bindIndex = 0

        for segment in segments {
            switch segment {
            case let .text(text):
                output.append(text)
            case .bind:
                switch mode {
                case .binded:
                    output.append(dialect.bindKey(bindIndex + 1))
                case .plain:
                    output.append(formattedValues[bindIndex])
                }
                bindIndex += 1
            }
        }

        return output.joined()
    }
}
