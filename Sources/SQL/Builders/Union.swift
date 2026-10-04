//
//  Union.swift
//  SwifQL
//
//  Created by Taylor McIntyre on 2020-01-15.
//

import Foundation

//MARK: UNION

public class Union: SQLable {
    public var parts: [SQLPart]
    
    public convenience init (_ selection: SQLable...) {
        self.init(selection)
    }

    public convenience init (all selection: SQLable...) {
        self.init(selection, all: true)
    }
    
    public init (_ selections: [SQLable], all: Bool = false) {
        var children: [SQLPart] = []
        for (i, v) in selections.enumerated() {
            if i > 0 {
                children.append(o: .space)
                children.append(o: .union)
                if all {
                    children.append(o: .space)
                    children.append(o: .all)
                }
                children.append(o: .space)
            }
            children.append(contentsOf: _SQLStructuralComposition.nestedStatementValueParts(for: v))
        }
        if selections.isEmpty {
            children = [SQLPartOperator.openBracket]
        }
        parts = [SQLStructuralFramePart(region: .setResult, children: children)]
    }
}

enum _SQLSetOperationKind {
    case union
    case unionAll
    case unionByName
    case unionAllByName
    case intersect
    case intersectAll
    case except
    case exceptAll

    var operatorParts: [SQLPart] {
        switch self {
        case .union:
            return [SQLPartOperator.union]
        case .unionAll:
            return [SQLPartOperator.union, SQLPartOperator.space, SQLPartOperator.all]
        case .unionByName:
            return [SQLPartOperator.union, SQLPartOperator.space, SQLPartOperator.custom("BY NAME")]
        case .unionAllByName:
            return [
                SQLPartOperator.union,
                SQLPartOperator.space,
                SQLPartOperator.all,
                SQLPartOperator.space,
                SQLPartOperator.custom("BY NAME")
            ]
        case .intersect:
            return [SQLPartOperator.custom("INTERSECT")]
        case .intersectAll:
            return [SQLPartOperator.custom("INTERSECT"), SQLPartOperator.space, SQLPartOperator.all]
        case .except:
            return [SQLPartOperator.custom("EXCEPT")]
        case .exceptAll:
            return [SQLPartOperator.custom("EXCEPT"), SQLPartOperator.space, SQLPartOperator.all]
        }
    }
}

struct _SQLSetOperationBuilder: SQLable {
    let parts: [SQLPart]

    init(
        _ lhs: SQLable,
        _ rhs: SQLable,
        kind: _SQLSetOperationKind
    ) {
        let children: [SQLPart] =
            _SQLStructuralComposition.nestedStatementValueParts(for: lhs)
            + [SQLPartOperator.space]
            + kind.operatorParts
            + [SQLPartOperator.space]
            + _SQLStructuralComposition.nestedStatementValueParts(for: rhs)

        parts = [SQLStructuralFramePart(region: .setResult, children: children)]
    }
}
