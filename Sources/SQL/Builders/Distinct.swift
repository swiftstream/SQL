//
//  Distinct.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/03/2019.
//

import Foundation

//MARK: DISTINCT

public class Distinct: SQLable {
    public var parts: [SQLPart]

    /// Narrow internal metadata for declarative SELECT modifier ownership.
    ///
    /// `true` when this instance already carries one or more output projections
    /// (historical `Distinct(field...)` or `andAlso(nonEmptyFields)`). Not a
    /// public API. Never inferred from rendered SQL/token history.
    internal var _declarativeCarriesProjection: Bool

    public convenience init (_ field: SQLable...) {
        self.init(field)
    }

    public init (_ fields: [SQLable]) {
        parts = []
        _declarativeCarriesProjection = !fields.isEmpty
        parts.append(o: .distinct)
        parts.append(o: .space)
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
    }

    public convenience init (on field: SQLable...) {
        self.init(on: field)
    }

    public init (on fields: [SQLable]) {
        parts = []
        _declarativeCarriesProjection = false
        parts.append(o: .distinct)
        parts.append(o: .space)
        parts.append(o: .on)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeBracket)
    }

    public func andAlso(_ fields: SQLable...) -> Distinct {
        andAlso(fields)
    }

    public func andAlso(_ fields: [SQLable]) -> Distinct {
        if !fields.isEmpty {
            _declarativeCarriesProjection = true
        }
        parts.append(o: .space)
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return self
    }
}
