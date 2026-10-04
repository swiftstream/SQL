//
//  Dialect.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

open class SQLDialect {
    open var id: String? { nil }
    
    public static var mysql: SQLDialect {
        MySQLDialect()
    }
    
    public static var psql: SQLDialect {
        PostgreSQLDialect()
    }

    public static var duck: SQLDialect {
        DuckDialect()
    }
    
    public static var all: [SQLDialect] {
        [.psql, .mysql, .duck]
    }
    
    /// Good choice only for super short and universal queries like `BEGIN;`, `ROLLBACK;`, `COMMIT;`
    public static var any: SQLDialect {
        .init()
    }
    
    public init () {}
    
    open func boolValue(_ value: Bool) -> String {
        value ? "TRUE" : "FALSE"
    }
    
    open var arrayStart: String { "" }
    open var emptyArrayStart: String { arrayStart }
    
    open var arraySeparator: String { Operator.comma._value }
    
    open var arrayEnd: String { "" }
    open var emptyArrayEnd: String { arrayEnd }
    
    open func schemaName(_ value: String) -> String { value }

    open func catalogName(_ value: String) -> String { schemaName(value) }

    /// Renders a terminal database-object identifier. The raw default keeps
    /// legacy SQLDialect subclasses source-compatible.
    open func identifier(_ value: String) -> String { value }
    
    open func tableName(_ value: String) -> String { value }
    
    open func alias(_ value: String) -> String { value }
    
    open func column(_ value: String) -> String { value }
    
    open func stringValue(_ value: String) -> String { value.singleQuotted }
    
    open func uuidValue(_ value: UUID) -> String { stringValue(value.uuidString) }

    open func pureDateValue(_ value: PureDate) -> String {
        stringValue(value.description)
    }

    open func pureTimeValue(_ value: PureTime) -> String {
        stringValue(value.description)
    }

    open func dateTimeValue(_ value: DateTime) -> String {
        stringValue(value.description)
    }

    open func intervalValue(_ value: Interval) -> String {
        guard let months = value.months,
              let days = value.days,
              let microseconds = value.microseconds else {
            return stringValue(value == .positiveInfinity ? "infinity" : "-infinity")
        }
        return stringValue("\(months) months \(days) days \(microseconds) microseconds")
    }
    
    open func jsonField(_ value: String) -> String { value }
    
    open func tableName(_ tableName: String, andAlias alias: String) -> String {
        self.tableName(tableName) + " AS " + self.alias(alias)
    }
    
    open func keyPath(_ keyPath: SQLPartKeyPath) -> String {
        "<key_path_should_be_here: override dialect function to fix>"
    }

    open func keyPath(
        _ keyPath: SQLPartKeyPath,
        context: SQLRenderContext
    ) -> String {
        self.keyPath(keyPath)
    }

    /// Selects an open dialect representation when a hybrid value provides
    /// one. Leaving this unset preserves the historical PostgreSQL/MySQL
    /// switch and custom-dialect fallback behavior.
    open var hybridRepresentationKey: SQLHybridRepresentationKey? { nil }

    /// Renders a semantic SQL type. The default preserves the historical
    /// textual spelling, including raw and nested `Type` compatibility.
    open func type(_ type: Type) -> String { type.name }

    func defaultSamplingParts(_ sample: SQLPartSampling) -> [SQLPart] {
        sample.renderedParts(
            argumentParts: sample.arguments.map { $0.parts },
            seedParts: sample.seed?.parts,
            repeatabilityParts: sample.repeatability?.parts
        )
    }

    /// Renders a structured sampling clause through the normal recursive
    /// parts pipeline. The default keeps sampling arguments as ordinary
    /// values, so custom dialects inherit normal bind collection.
    open func sampling(_ sample: SQLPartSampling) -> [SQLPart] {
        defaultSamplingParts(sample)
    }

    open func sampling(
        _ sample: SQLPartSampling,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .incomplete(sampling(sample))
    }

    func defaultLambdaParts(_ lambda: SQLPartLambda) -> [SQLPart] {
        var parts: [SQLPart] = [
            SQLPartOperator.custom("lambda"),
            SQLPartOperator.space
        ]
        for (index, parameter) in lambda.parameters.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: parameter.parts)
        }
        parts.append(o: .space, .custom(":"), .space)
        parts.append(contentsOf: lambda.body)
        return parts
    }

    /// Renders a structured SQL lambda through the normal recursive parts
    /// pipeline. The default preserves the historical `lambda ... : ...`
    /// spelling and ordinary body-value binding.
    open func lambda(_ lambda: SQLPartLambda) -> [SQLPart] {
        defaultLambdaParts(lambda)
    }

    open func lambda(
        _ lambda: SQLPartLambda,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .incomplete(self.lambda(lambda))
    }

    open func hybridOperator(_ hybrid: SQLHybridOperator) -> SQLPartOperator {
        if let key = hybridRepresentationKey {
            return hybrid.representation(for: key)
                ?? SQLPartOperator(
                    "<hybrid_operator_requires_explicit_\(key.name)_branch>"
                )
        }

        switch self {
        case .psql:
            return hybrid.representation(for: .psql)
                ?? SQLPartOperator("<hybrid_operator_requires_psql_branch>")
        case .mysql:
            return hybrid.representation(for: .mysql)
                ?? SQLPartOperator("<hybrid_operator_requires_mysql_branch>")
        default:
            return hybrid.representation(for: .mysql)
                ?? SQLPartOperator("<hybrid_operator_requires_mysql_branch>")
        }
    }
    
    open func date(_ value: Date) -> String {
        "<date_should_be_here: override dialect function to fix>"
    }
    
    open var null: String { "NULL" }
    
    open func safeValue(_ value: Any?) -> String {
        guard let value = value else { return null }
        switch value {
        case let v as String: return stringValue(v)
        case let v as UUID: return uuidValue(v)
        case let v as PureDate: return pureDateValue(v)
        case let v as PureTime: return pureTimeValue(v)
        case let v as DateTime: return dateTimeValue(v)
        case let v as Interval: return intervalValue(v)
        case let v as Bool: return boolValue(v)
        case let v as UInt: return String(describing: v)
        case let v as UInt8: return String(describing: v)
        case let v as UInt16: return String(describing: v)
        case let v as UInt32: return String(describing: v)
        case let v as UInt64: return String(describing: v)
        case let v as Int: return String(describing: v)
        case let v as Int8: return String(describing: v)
        case let v as Int16: return String(describing: v)
        case let v as Int32: return String(describing: v)
        case let v as Int64: return String(describing: v)
        case let v as Float: return String(describing: v)
        case let v as Double: return String(describing: v)
        case let v as Decimal: return String(describing: v)
        default: return stringValue(String(describing: "<unsafe value>")) // TODO:
        }
    }

    open func inlineUnsafeValue(
        _ value: Encodable,
        context: SQLRenderContext
    ) -> String? {
        nil
    }

    open func starExcludeParts(_ part: SQLStarExcludePart) -> [SQLPart] {
        var parts: [SQLPart] = [
            SQLPartOperator("EXCLUDE"),
            SQLPartOperator.space,
            SQLPartOperator.openBracket
        ]
        for (index, columnName) in part.columnNames.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(SQLPartColumn(columnName))
        }
        parts.append(o: .closeBracket)
        return parts
    }

    func defaultStarReplaceParts(_ part: SQLStarReplacePart) -> [SQLPart] {
        var parts: [SQLPart] = [
            SQLPartOperator("REPLACE"),
            SQLPartOperator.space,
            SQLPartOperator.openBracket
        ]
        for (index, entry) in part.entries.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: entry.expressionParts)
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartColumn(entry.columnName))
        }
        parts.append(o: .closeBracket)
        return parts
    }

    open func starReplaceParts(_ part: SQLStarReplacePart) -> [SQLPart] {
        defaultStarReplaceParts(part)
    }

    open func starReplaceParts(
        _ part: SQLStarReplacePart,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .incomplete(starReplaceParts(part))
    }

    open func starRenameParts(_ part: SQLStarRenamePart) -> [SQLPart] {
        var parts: [SQLPart] = [
            SQLPartOperator("RENAME"),
            SQLPartOperator.space,
            SQLPartOperator.openBracket
        ]
        for (index, entry) in part.entries.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(SQLPartColumn(entry.oldColumnName))
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartColumn(entry.newColumnName))
        }
        parts.append(o: .closeBracket)
        return parts
    }
    
    // MARK: - Binding (for formatter)
    
    open var bindSymbol: String { "§§§" }
    
    open func bindKey(_ i: Int) -> String { "?" }
}

extension SQLDialect: Equatable {
    public static func == (lhs: SQLDialect, rhs: SQLDialect) -> Bool {
        lhs.id == rhs.id
    }
}
