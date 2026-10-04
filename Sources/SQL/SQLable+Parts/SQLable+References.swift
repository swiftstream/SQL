//
//  SQLable+References.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: REFERENCES

extension SQLable {
    public var references: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .references)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

