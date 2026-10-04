//
//  SQLable+Fulltext.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: @@

extension SQLable {
    public func fulltext(_ part: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .fulltext)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
