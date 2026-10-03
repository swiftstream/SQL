//
//  SwifQLable+Fulltext.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: @@

extension SwifQLable {
    public func fulltext(_ part: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .fulltext)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
