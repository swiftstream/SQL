//
//  Predicates.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

public struct SQLPredicate: SQLable {
    public var parts: [SQLPart]
    
    public init (operator: SQLPartOperator, lhs: SQLable, rhs: SQLable?) {
        parts = lhs.parts
        parts.append(o: .space)
        if let rhs = rhs {
            parts.append(o: `operator`)
            parts.append(o: .space)
            parts.append(contentsOf: rhs.parts)
        } else {
            switch `operator` {
            case .equal: parts.append(o: .isNull)
            case .notEqual: parts.append(o: .isNotNull)
            default: parts.append(o: .null)
            }
        }
    }
}

public func > (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .greaterThan, lhs: lhs, rhs: rhs)
}

public func < (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .lessThan, lhs: lhs, rhs: rhs)
}

public func >= (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .greaterThanOrEqual, lhs: lhs, rhs: rhs)
}

public func <= (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .lessThanOrEqual, lhs: lhs, rhs: rhs)
}

public func == <T>(lhs: T, rhs: T.AType) -> SQLable
    where T: SQLUniversalKeyPath, T: SQLable, T.AType: RawRepresentable, T.AType: Encodable {
    SQLPredicate(operator: .equal, lhs: lhs, rhs: SQLableParts(parts: SQLPartSafeValue(rhs.rawValue)))
}
public func == <T>(lhs: T, rhs: T.AType.RawValue) -> SQLable
    where T: SQLUniversalKeyPath, T: SQLable, T.AType: RawRepresentable, T.AType.RawValue: SQLable {
    SQLPredicate(operator: .equal, lhs: lhs, rhs: SQLableParts(parts: SQLPartSafeValue(rhs)))
}
public func != <T>(lhs: T, rhs: T.AType) -> SQLable
    where T: SQLUniversalKeyPath, T: SQLable, T.AType: RawRepresentable, T.AType: Encodable {
    SQLPredicate(operator: .notEqual, lhs: lhs, rhs: SQLableParts(parts: SQLPartSafeValue(rhs.rawValue)))
}
public func != <T>(lhs: T, rhs: T.AType.RawValue) -> SQLable
    where T: SQLUniversalKeyPath, T: SQLable, T.AType: RawRepresentable, T.AType.RawValue: SQLable {
    SQLPredicate(operator: .notEqual, lhs: lhs, rhs: SQLableParts(parts: SQLPartSafeValue(rhs)))
}

public func == (lhs: SQLable, rhs: SQLable?) -> SQLable {
    SQLPredicate(operator: .equal, lhs: lhs, rhs: rhs)
}

public func != (lhs: SQLable, rhs: SQLable?) -> SQLable {
    SQLPredicate(operator: .notEqual, lhs: lhs, rhs: rhs)
}

public func == (lhs: SQLable, rhs: Bool) -> SQLable {
    SQLPredicate(operator: .equal, lhs: lhs, rhs: SQLPartBool(rhs))
}

public func != (lhs: SQLable, rhs: Bool) -> SQLable {
    SQLPredicate(operator: .notEqual, lhs: lhs, rhs: SQLPartBool(rhs))
}

public func == (lhs: Bool, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .equal, lhs: SQLPartBool(lhs), rhs: rhs)
}

public func != (lhs: Bool, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .notEqual, lhs: SQLPartBool(lhs), rhs: rhs)
}

public func && (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .and, lhs: lhs, rhs: rhs)
}

public func || (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .or, lhs: lhs, rhs: rhs)
}

/// Originally: @>
infix operator ||> : AdditionPrecedence
public func ||> (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .contains, lhs: lhs, rhs: rhs)
}

/// Originally: <@
infix operator <|| : AdditionPrecedence
public func <|| (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .containedBy, lhs: lhs, rhs: rhs)
}

/// Originally: BETWEEN
infix operator <> : AdditionPrecedence
public func <> (lhs: SQLable, rhs: SQLable) -> SQLable {
    SQLPredicate(operator: .between, lhs: lhs, rhs: rhs)
}

// TBD: Table 9.43. json and jsonb Operators (https://www.postgresql.org/docs/current/functions-json.html)
// TBD: Table 9.44. Additional jsonb Operators (https://www.postgresql.org/docs/current/functions-json.html)

//OR ||
