//
//  Union.swift
//  SwifQL
//
//  Created by Taylor McIntyre on 2020-01-15.
//

import Foundation

//MARK: UNION

public class Union: SwifQLable {
    public var parts: [SwifQLPart]
    
    public convenience init (_ selection: SwifQLable...) {
        self.init(selection)
    }

    public convenience init (all selection: SwifQLable...) {
        self.init(selection, all: true)
    }
    
    public init (_ selections: [SwifQLable], all: Bool = false) {
        var children: [SwifQLPart] = []
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
            children.append(contentsOf: _SwifQLStructuralComposition.nestedStatementValueParts(for: v))
        }
        if selections.isEmpty {
            children = [SwifQLPartOperator.openBracket]
        }
        parts = [SwifQLStructuralFramePart(region: .setResult, children: children)]
    }
}

enum _SwifQLSetOperationKind {
    case union
    case unionAll
    case unionByName
    case unionAllByName
    case intersect
    case intersectAll
    case except
    case exceptAll

    var operatorParts: [SwifQLPart] {
        switch self {
        case .union:
            return [SwifQLPartOperator.union]
        case .unionAll:
            return [SwifQLPartOperator.union, SwifQLPartOperator.space, SwifQLPartOperator.all]
        case .unionByName:
            return [SwifQLPartOperator.union, SwifQLPartOperator.space, SwifQLPartOperator.custom("BY NAME")]
        case .unionAllByName:
            return [
                SwifQLPartOperator.union,
                SwifQLPartOperator.space,
                SwifQLPartOperator.all,
                SwifQLPartOperator.space,
                SwifQLPartOperator.custom("BY NAME")
            ]
        case .intersect:
            return [SwifQLPartOperator.custom("INTERSECT")]
        case .intersectAll:
            return [SwifQLPartOperator.custom("INTERSECT"), SwifQLPartOperator.space, SwifQLPartOperator.all]
        case .except:
            return [SwifQLPartOperator.custom("EXCEPT")]
        case .exceptAll:
            return [SwifQLPartOperator.custom("EXCEPT"), SwifQLPartOperator.space, SwifQLPartOperator.all]
        }
    }
}

struct _SwifQLSetOperationBuilder: SwifQLable {
    let parts: [SwifQLPart]

    init(
        _ lhs: SwifQLable,
        _ rhs: SwifQLable,
        kind: _SwifQLSetOperationKind
    ) {
        let children: [SwifQLPart] =
            _SwifQLStructuralComposition.nestedStatementValueParts(for: lhs)
            + [SwifQLPartOperator.space]
            + kind.operatorParts
            + [SwifQLPartOperator.space]
            + _SwifQLStructuralComposition.nestedStatementValueParts(for: rhs)

        parts = [SwifQLStructuralFramePart(region: .setResult, children: children)]
    }
}
