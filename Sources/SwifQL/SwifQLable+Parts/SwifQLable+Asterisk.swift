//
//  SQLable+Asterisk.swift
//  SwifQL
//
//  Created by Mihael Isaev on 31.01.2020.
//

import Foundation

//MARK: *

extension SQLable {
    public var asterisk: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(SQLPartOperator("*", semanticRole: .starProjection))
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Excludes structural column names from a star expression.
    public func exclude(
        _ first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        let role: SQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SQLStarExcludePart(
                columnNames: ([first] + rest).map(\.lastPath),
                semanticRole: role
            )
        )
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Replaces selected columns in a star expression.
    public func replace(
        _ first: StarReplacement,
        _ rest: StarReplacement...
    ) -> SQLable {
        let role: SQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SQLStarReplacePart(
                entries: [first] + rest,
                semanticRole: role
            )
        )
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Renames selected columns in a star expression.
    public func rename(
        _ first: StarRename,
        _ rest: StarRename...
    ) -> SQLable {
        let role: SQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SQLStarRenamePart(
                entries: [first] + rest,
                semanticRole: role
            )
        )
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Builds a `GLOB` pattern expression.
    public func glob(_ pattern: SQLable) -> SQLable {
        applyingPatternOperator(.custom("GLOB"), to: pattern)
    }

    /// Builds a `SIMILAR TO` pattern expression.
    public func similarTo(_ pattern: SQLable) -> SQLable {
        applyingPatternOperator(.custom("SIMILAR TO"), to: pattern)
    }

    /// Builds a `NOT SIMILAR TO` pattern expression.
    public func notSimilarTo(_ pattern: SQLable) -> SQLable {
        applyingPatternOperator(.custom("NOT SIMILAR TO"), to: pattern)
    }

}
