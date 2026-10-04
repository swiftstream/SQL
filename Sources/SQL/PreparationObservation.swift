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
        let query = render(parts, context: SQLRenderContext())
        let prepared = SQLPrepared(
            dialect: dialect,
            query: query,
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

    private func render(_ parts: [SQLPart], context: SQLRenderContext) -> String {
        parts.map { part in
            if let scopedPart = part as? SQLScopedPart {
                return render(
                    scopedPart.parts,
                    context: context.appending(scopedPart.scope)
                )
            }

            if let observedUnsafe = part as? SQLUnsafeValueObservationPart {
                guard mode == .observeUnsafeValues else {
                    return ""
                }
                unsafeValueOccurrences.append(
                    .init(
                        value: observedUnsafe.unsafeValue.unsafeValue,
                        disposition: .notBound
                    )
                )
                return ""
            }

            switch part {
            case let v as SQLStructuralFramePart:
                return render(v.children, context: SQLRenderContext())
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
                return render(clauseParts, context: childContext)
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
                return render(clauseParts, context: childContext)
            case let v as SQLPartArray:
                guard !v.elements.isEmpty else {
                    return dialect.emptyArrayStart + dialect.emptyArrayEnd
                }
                var string = dialect.arrayStart
                for (i, element) in v.elements.enumerated() {
                    if i > 0 {
                        string += dialect.arraySeparator
                    }
                    string += render(element.parts, context: context)
                }
                return string + dialect.arrayEnd
            case let v as SQLPartBool:
                return dialect.boolValue(v.value)
            case is SQLPartNull:
                return dialect.null
            case let v as SQLPartCatalog:
                return dialect.catalogName(v.name)
            case let v as SQLPartIdentifier:
                return dialect.identifier(v.name)
            case let v as SQLPartSchema:
                guard let schema = v.schema else { return "" }
                return dialect.schemaName(schema)
            case let v as SQLPartTable:
                if let schema = v.schema {
                    return dialect.schemaName(schema) + "." + dialect.tableName(v.table)
                }
                return dialect.tableName(v.table)
            case let v as SQLPartTableWithAlias:
                if let schema = v.schema {
                    return dialect.schemaName(schema) + "." + dialect.tableName(v.table, andAlias: v.alias)
                }
                return dialect.tableName(v.table, andAlias: v.alias)
            case let v as SQLPartAlias:
                return dialect.alias(v.alias)
            case let v as SQLPartKeyPath:
                return dialect.keyPath(v, context: context)
            case let v as SQLPartSampling:
                switch mode {
                case .legacy:
                    return render(dialect.sampling(v), context: context)
                case .observeUnsafeValues:
                    let observed = dialect.sampling(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    return render(observed.parts, context: context)
                }
            case let v as SQLPartLambda:
                switch mode {
                case .legacy:
                    return render(dialect.lambda(v), context: context)
                case .observeUnsafeValues:
                    let observed = dialect.lambda(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    return render(observed.parts, context: context)
                }
            case let v as SQLPartType:
                return dialect.type(v.type)
            case let v as SQLPartColumn:
                return dialect.column(v.name)
            case let v as SQLStarExcludePart:
                return render(dialect.starExcludeParts(v), context: context)
            case let v as SQLStarReplacePart:
                switch mode {
                case .legacy:
                    return render(dialect.starReplaceParts(v), context: context)
                case .observeUnsafeValues:
                    let observed = dialect.starReplaceParts(
                        v,
                        observingUnsafeValues: SQLUnsafeValueObservation()
                    )
                    if !observed.isComplete {
                        traceIsComplete = false
                    }
                    return render(observed.parts, context: context)
                }
            case let v as SQLStarRenamePart:
                return render(dialect.starRenameParts(v), context: context)
            case let v as SQLPartOperator:
                return v._value
            case let v as SQLHybridOperator:
                return dialect.hybridOperator(v)._value
            case let v as SQLPartDate:
                return dialect.date(v.date)
            case let v as SQLPartSafeValue:
                return dialect.safeValue(v.safeValue)
            case let v as SQLPartUnsafeValue:
                if let inlineValue = dialect.inlineUnsafeValue(v.unsafeValue, context: context) {
                    if mode == .observeUnsafeValues {
                        unsafeValueOccurrences.append(
                            .init(value: v.unsafeValue, disposition: .notBound)
                        )
                    }
                    return inlineValue
                }

                let index = values.count
                if mode == .observeUnsafeValues {
                    unsafeValueOccurrences.append(
                        .init(value: v.unsafeValue, disposition: .bound(index: index))
                    )
                }
                values.append(v.unsafeValue)
                formattedValues.append(dialect.safeValue(v.unsafeValue))
                return dialect.bindSymbol
            default:
                return ""
            }
        }.joined(separator: "")
    }
}
