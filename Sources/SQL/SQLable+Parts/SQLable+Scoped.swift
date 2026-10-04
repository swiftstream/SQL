//
//  SQLable+Scoped.swift
//  SwifQL
//

import Foundation

extension SQLable {
    public func scoped(_ scope: SQLRenderScope) -> SQLable {
        SQLableParts(parts: [SQLScopedPart(scope: scope, parts: parts)])
    }
}
