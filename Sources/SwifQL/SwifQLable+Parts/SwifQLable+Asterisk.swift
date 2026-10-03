//
//  SwifQLable+Asterisk.swift
//  SwifQL
//
//  Created by Mihael Isaev on 31.01.2020.
//

import Foundation

//MARK: *

extension SwifQLable {
    public var asterisk: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(SwifQLPartOperator("*", semanticRole: .starProjection))
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Excludes structural column names from a star expression.
    public func exclude(
        _ first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SwifQLable {
        let role: SwifQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SwifQLStarExcludePart(
                columnNames: ([first] + rest).map(\.lastPath),
                semanticRole: role
            )
        )
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Replaces selected columns in a star expression.
    public func replace(
        _ first: StarReplacement,
        _ rest: StarReplacement...
    ) -> SwifQLable {
        let role: SwifQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SwifQLStarReplacePart(
                entries: [first] + rest,
                semanticRole: role
            )
        )
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Renames selected columns in a star expression.
    public func rename(
        _ first: StarRename,
        _ rest: StarRename...
    ) -> SwifQLable {
        let role: SwifQLSemanticRole? = ownsStarProjectionSemanticRole ? .starProjection : nil
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(
            SwifQLStarRenamePart(
                entries: [first] + rest,
                semanticRole: role
            )
        )
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    /// Builds a `GLOB` pattern expression.
    public func glob(_ pattern: SwifQLable) -> SwifQLable {
        applyingPatternOperator(.custom("GLOB"), to: pattern)
    }

    /// Builds a `SIMILAR TO` pattern expression.
    public func similarTo(_ pattern: SwifQLable) -> SwifQLable {
        applyingPatternOperator(.custom("SIMILAR TO"), to: pattern)
    }

    /// Builds a `NOT SIMILAR TO` pattern expression.
    public func notSimilarTo(_ pattern: SwifQLable) -> SwifQLable {
        applyingPatternOperator(.custom("NOT SIMILAR TO"), to: pattern)
    }

}
