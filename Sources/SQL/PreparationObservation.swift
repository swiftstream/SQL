//
//  PreparationObservation.swift
//  SwifQL
//
//  Created by SwifQL contributors.
//

import Foundation

public struct SQLUnsafeValueOccurrence {
    public enum Disposition: Equatable, Sendable {
        case bound(index: Int)
        case notBound
    }

    public let value: Encodable
    public let disposition: Disposition

    init(value: Encodable, disposition: Disposition) {
        self.value = value
        self.disposition = disposition
    }
}

public enum SQLUnsafeValueTrace {
    case complete([SQLUnsafeValueOccurrence])
    case unavailable
}

public struct SQLObservedPrepared {
    public let prepared: SQLPrepared
    public let unsafeValueTrace: SQLUnsafeValueTrace

    init(prepared: SQLPrepared, unsafeValueTrace: SQLUnsafeValueTrace) {
        self.prepared = prepared
        self.unsafeValueTrace = unsafeValueTrace
    }
}

public struct SQLUnsafeValueObservation {
    public func notBound(_ unsafeValue: SQLPartUnsafeValue) -> SQLPart {
        SQLUnsafeValueObservationPart(unsafeValue: unsafeValue)
    }
}

public struct SQLObservedParts {
    public let parts: [SQLPart]

    let isComplete: Bool

    public static func complete(_ parts: [SQLPart]) -> SQLObservedParts {
        .init(parts: parts, isComplete: true)
    }

    static func incomplete(_ parts: [SQLPart]) -> SQLObservedParts {
        .init(parts: parts, isComplete: false)
    }

    private init(parts: [SQLPart], isComplete: Bool) {
        self.parts = parts
        self.isComplete = isComplete
    }
}

private struct SQLUnsafeValueObservationPart: SQLPart {
    let unsafeValue: SQLPartUnsafeValue
}

enum SQLPreparationMode {
    case legacy
    case observeUnsafeValues
}

enum SQLPreparedOutputSegment {
    case text(String)
    case bind(marker: String)
}

struct SQLPreparedOutput {
    private(set) var segments: [SQLPreparedOutputSegment] = []

    mutating func append(text: String) {
        segments.append(.text(text))
    }

    mutating func append(bindMarker marker: String) {
        segments.append(.bind(marker: marker))
    }
}

struct SQLPreparationResult {
    let prepared: SQLPrepared
    let unsafeValueTrace: SQLUnsafeValueTrace
}

final class SQLPreparationRenderer {
    private let dialect: SQLDialect
    private let mode: SQLPreparationMode

    private var values: [Encodable] = []
    private var formattedValues: [String] = []
    private var unsafeValueOccurrences: [SQLUnsafeValueOccurrence] = []
    private var traceIsComplete = true

    init(dialect: SQLDialect, mode: SQLPreparationMode) {
        self.dialect = dialect
        self.mode = mode
    }

    func prepare(_ parts: [SQLPart]) -> SQLPreparationResult {
        var output = SQLPreparedOutput()
        render(parts, context: SQLRenderContext(), into: &output)
        let prepared = SQLPrepared(
            dialect: dialect,
            segments: output.segments,
            values: values,
            formattedValues: formattedValues
        )

        let trace: SQLUnsafeValueTrace
        switch mode {
        case .legacy:
            trace = .unavailable
        case .observeUnsafeValues:
            trace = traceIsComplete ? .complete(unsafeValueOccurrences) : .unavailable
        }

        return .init(prepared: prepared, unsafeValueTrace: trace)
    }

    private func render(
        _ parts: [SQLPart],
        context: SQLRenderContext,
        into output: inout SQLPreparedOutput
    ) {
        for part in parts {
            if let scopedPart = part as? SQLScopedPart {
                render(
                    scopedPart.parts,
                    context: context.appending(scopedPart.scope),
                    into: &output
                )
                continue
            }

            if let observedUnsafe = part as? SQLUnsafeValueObservationPart {
                guard mode == .observeUnsafeValues else { continue }
                unsafeValueOccurrences.append(
                    .init(
                        value: observedUnsafe.unsafeValue.unsafeValue,
                        disposition: .notBound
                    )
                )
                continue
            }

            switch part {
            case let v as SQLExpressionSubscriptPart:
                // Render each child once so observation and prepared values
                // remain in base-then-item order for every dialect.
                switch dialect.subscriptBaseGrouping(v) {
                case .direct:
                    render(v.baseParts, context: context, into: &output)
                case .parenthesized:
                    output.append(text: "(")
                    render(v.baseParts, context: context, into: &output)
                    output.append(text: ")")
                }
                output.append(text: "[")
                render(v.itemParts, context: context, into: &output)
                output.append(text: "]")
            case let v as SQLStructuralFramePart:
                render(v.children, context: SQLRenderContext(), into: &output)
            case let v as SQLGroupByPart:
                let childContext = v.owner.map {
                    context.appending($0.renderScope(for: .groupBy))
                } ?? context
                var clauseParts: [SQLPart] = []
                clauseParts.append(o: .group)
                clauseParts.append(o: .space)
                clauseParts.append(o: .by)
                clauseParts.append(o: .space)
                for (i, field) in v.fields.enumerated() {
                    if i > 0 {
                        clauseParts.append(o: .comma)
                        clauseParts.append(o: .space)
                    }
                    clauseParts.append(contentsOf: field)
                }
                render(clauseParts, context: childContext, into: &output)
            case let v as SQLOrderByPart:
                let childContext = v.owner.map {
                    context.appending($0.renderScope(for: .orderBy))
                } ?? context
                var clauseParts: [SQLPart] = []
                clauseParts.append(o: .order)
                clauseParts.append(o: .space)
                clauseParts.append(o: .by)
                clauseParts.append(o: .space)
                for (i, item) in v.items.enumerated() {
                    if i > 0 {
                        clauseParts.append(o: .comma)
                        clauseParts.append(o: .space)
                    }
                    clauseParts.append(contentsOf: item)
                }
                render(clauseParts, context: childContext, into: &output)
            case let v as SQLPartArray:
                guard !v.elements.isEmpty else {
                    output.append(text: dialect.emptyArrayStart + dialect.emptyArrayEnd)
                    continue
                }
                output.append(text: dialect.arrayStart)
                for (i, element) in v.elements.enumerated() {
                    if i > 0 {
                        output.append(text: dialect.arraySeparator)
                    }
                    render(element.parts, context: context, into: &output)
                }
                output.append(text: dialect.arrayEnd)
            case let v as SQLPartBool:
                output.append(text: dialect.boolValue(v.value))
            case is SQLPartNull:
                output.append(text: dialect.null)
            case let v as SQLPartCatalog:
                output.append(text: dialect.catalogName(v.name))
            case let v as SQLPartIdentifier:
                output.append(text: dialect.identifier(v.name))
            case let v as SQLPartSchema:
                if let schema = v.schema {
                    output.append(text: dialect.schemaName(schema))
                }
            case let v as SQLPartTable:
                var relation = ""
                if let catalog = v.catalog {
                    relation += dialect.catalogName(catalog) + "."
                }
                if let schema = v.schema {
                    relation += dialect.schemaName(schema) + "."
                }
                output.append(text: relation + dialect.tableName(v.table))
            case let v as SQLPartTableWithAlias:
                var relation = ""
                if let catalog = v.catalog {
                    relation += dialect.catalogName(catalog) + "."
                }
                if let schema = v.schema {
                    relation += dialect.schemaName(schema) + "."
                }
                output.append(text: relation + dialect.tableName(v.table, andAlias: v.alias))
            case let v as SQLPartAlias:
                output.append(text: dialect.alias(v.alias))
            case let v as SQLPartKeyPath:
                output.append(text: dialect.keyPath(v, context: context))
            case let v as SQLPartSampling:
                switch mode {
                case .legacy:
                    render(dialect.sampling(v), context: context, into: &output)
                case .observeUnsafeValues:
                    let observed = dialect.sampling(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    render(observed.parts, context: context, into: &output)
                }
            case let v as SQLPartLambda:
                switch mode {
                case .legacy:
                    render(dialect.lambda(v), context: context, into: &output)
                case .observeUnsafeValues:
                    let observed = dialect.lambda(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    render(observed.parts, context: context, into: &output)
                }
            case let v as SQLPartType:
                output.append(text: dialect.type(v.type))
            case let v as SQLPartColumn:
                output.append(text: dialect.column(v.name))
            case let v as SQLStarExcludePart:
                render(dialect.starExcludeParts(v), context: context, into: &output)
            case let v as SQLStarReplacePart:
                switch mode {
                case .legacy:
                    render(dialect.starReplaceParts(v), context: context, into: &output)
                case .observeUnsafeValues:
                    let observed = dialect.starReplaceParts(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    render(observed.parts, context: context, into: &output)
                }
            case let v as SQLStarRenamePart:
                render(dialect.starRenameParts(v), context: context, into: &output)
            case let v as SQLPartOperator:
                output.append(text: v._value)
            case let v as SQLHybridOperator:
                output.append(text: dialect.hybridOperator(v)._value)
            case let v as SQLPartDate:
                output.append(text: dialect.date(v.date))
            case let v as SQLPartSafeValue:
                output.append(text: dialect.safeValue(v.safeValue))
            case let v as SQLPartUnsafeValue:
                if let inlineValue = dialect.inlineUnsafeValue(v.unsafeValue, context: context) {
                    if mode == .observeUnsafeValues {
                        unsafeValueOccurrences.append(
                            .init(value: v.unsafeValue, disposition: .notBound)
                        )
                    }
                    output.append(text: inlineValue)
                    continue
                }

                let index = values.count
                if mode == .observeUnsafeValues {
                    unsafeValueOccurrences.append(
                        .init(value: v.unsafeValue, disposition: .bound(index: index))
                    )
                }
                values.append(v.unsafeValue)
                formattedValues.append(dialect.safeValue(v.unsafeValue))
                output.append(bindMarker: dialect.bindSymbol)
            default:
                break
            }
        }
    }
}
