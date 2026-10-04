//
//  SQLable+Union.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: Union

extension SQLable {
    public var union: SQLable {
        let setResult = _SQLStructuralComposition.setResult(from: self)
        let fragmentParts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.union,
            SQLPartOperator.space
        ]
        let fragment = SQLableParts(parts: fragmentParts)
        return setResult.structurallyAppending(fragment)
    }

    public func union(_ selection: SQLable) -> SQLable {
        Union(self, selection)
    }

    public func union(all selection: SQLable) -> SQLable {
        Union(all: self, selection)
    }

    public func union(byName selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .unionByName)
    }

    public func union(allByName selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .unionAllByName)
    }

    public func intersect(_ selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .intersect)
    }

    public func intersect(all selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .intersectAll)
    }

    public func except(_ selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .except)
    }

    public func except(all selection: SQLable) -> SQLable {
        _SQLSetOperationBuilder(self, selection, kind: .exceptAll)
    }
}
