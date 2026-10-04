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
    
    func string(from query: String, with formattedValues: [String]) -> String {
        switch mode {
        case .binded:
            return binded(query)
        case .plain:
            return plain(query: query, with: formattedValues)
        }
    }
    
    private func binded(_ query: String, _ valueRetriever: @escaping (Int) -> String) -> String {
        let rawChars: [Character] = Array(query)
        var finalChars: [Character] = []
        var skipTill = -1
        var b = 1
        for (i, char) in rawChars.enumerated() {
            guard skipTill < i else { continue }
            guard char == dialect.bindSymbol.first else {
                finalChars.append(char)
                continue
            }
            if dialect.bindSymbol.count > 1 {
                guard rawChars.count >= i + dialect.bindSymbol.count else { continue }
                for n in 1...dialect.bindSymbol.count - 1 {
                    guard rawChars[i + n] == Array(dialect.bindSymbol)[n] else { continue }
                }
                skipTill = i + dialect.bindSymbol.count - 1
            }
            finalChars.append(contentsOf: Array(valueRetriever(b)))
            b = b + 1
        }
        return String(finalChars)
    }
    
    private func binded(_ query: String) -> String {
        binded(query) { self.dialect.bindKey($0) }
    }
    
    private func plain(query: String, with formattedValues: [String]) -> String {
        binded(query) { formattedValues[$0 - 1] }
    }
}

extension String {
    fileprivate func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}
