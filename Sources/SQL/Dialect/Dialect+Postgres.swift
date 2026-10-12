//
//  Dialect+Postgres.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

private func postgresDateParts(_ value: PureDate) -> (date: String, isBC: Bool) {
    guard let year = value.year,
          let month = value.month,
          let day = value.day else {
        return (value.description, false)
    }

    guard year <= 0 else {
        return (value.description, false)
    }

    let bcYear = year.magnitude.addingReportingOverflow(1).partialValue
    let yearDigits = String(bcYear)
    let yearText = String(repeating: "0", count: max(0, 4 - yearDigits.count)) + yearDigits
    func padded(_ component: Int) -> String {
        let digits = String(component)
        return String(repeating: "0", count: max(0, 2 - digits.count)) + digits
    }
    return ("\(yearText)-\(padded(month))-\(padded(day))", true)
}

private func postgresDateInput(_ value: PureDate) -> String {
    let parts = postgresDateParts(value)
    return parts.date + (parts.isBC ? " BC" : "")
}

private func postgresDateTimeInput(_ value: DateTime) -> String {
    guard let date = value.date, let time = value.time else {
        return value.description
    }
    let parts = postgresDateParts(date)
    return "\(parts.date) \(time.description)" + (parts.isBC ? " BC" : "")
}

private func postgresTableSampleParts(
    _ sample: SQLPartSampling,
    method: SampleMethod
) -> [SQLPart] {
    var parts: [SQLPart] = [
        SQLPartOperator.custom("TABLESAMPLE"),
        SQLPartOperator.space
    ]
    parts.append(contentsOf: method.parts)
    parts.append(o: .openBracket)
    for (index, argument) in sample.arguments.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(contentsOf: argument.parts)
    }
    parts.append(o: .closeBracket)
    if let repeatability = sample.repeatability {
        parts.append(o: .space, .custom("REPEATABLE"), .space, .openBracket)
        parts.append(contentsOf: repeatability.parts)
        parts.append(o: .closeBracket)
    }
    return parts
}

class PostgreSQLDialect: SQLDialect {
    override var id: String? { "psql" }

    override func subscriptBaseGrouping(
        _ part: SQLExpressionSubscriptPart
    ) -> SQLSubscriptBaseGrouping {
        guard part.baseParts.count == 1 else { return .parenthesized }
        switch part.baseParts[0] {
        case is SQLPartColumn, is SQLExpressionSubscriptPart:
            return .direct
        case let path as SQLPartKeyPath where path.paths.count == 1:
            return .direct
        default:
            return .parenthesized
        }
    }

    override func sampling(_ sample: SQLPartSampling) -> [SQLPart] {
        guard sample.construct == .tableSample, let method = sample.method else {
            return defaultSamplingParts(sample)
        }
        return postgresTableSampleParts(sample, method: method)
    }

    override func sampling(
        _ sample: SQLPartSampling,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .complete(sampling(sample))
    }

    override func lambda(
        _ lambda: SQLPartLambda,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .complete(defaultLambdaParts(lambda))
    }

    override func starReplaceParts(
        _ part: SQLStarReplacePart,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .complete(defaultStarReplaceParts(part))
    }
    
    override func schemaName(_ value: String) -> String { value.doubleQuotted }

    override func identifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    
    override func tableName(_ value: String) -> String { value.doubleQuotted }
    
    override func alias(_ value: String) -> String { value.doubleQuotted }
    
    override func column(_ value: String) -> String { value.doubleQuotted }
    
    override func jsonField(_ value: String) -> String { value.singleQuotted }
    
    override func keyPath(_ keyPath: SQLPartKeyPath) -> String {
        var result = ""
        if let schema = keyPath.schema {
            result.append(schemaName(schema))
        }
        if let table = keyPath.table {
            if result.count > 0 {
                result.append(".")
            }
            result.append(tableName(table))
        }
        for (i, v) in keyPath.paths.enumerated() {
            if i == 0 {
                if result.count > 0 {
                    result.append(".")
                }
                result.append(column(v))
            } else {
                if keyPath.asText, i == keyPath.paths.count - 1 {
                    result.append("->>")
                } else {
                    result.append("->")
                }
                result.append(jsonField(v))
            }
        }
        return result
    }
    
    private lazy var _dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }()
    
    override func date(_ value: Date) -> String {
        let date = _dateFormatter.string(from: value) => .timestamptz
        let result = |date|
        return result.prepare(self).plain
    }

    override func pureDateValue(_ value: PureDate) -> String {
        "DATE \(stringValue(postgresDateInput(value)))"
    }

    override func pureTimeValue(_ value: PureTime) -> String {
        "TIME \(stringValue(value.description))"
    }

    override func dateTimeValue(_ value: DateTime) -> String {
        "TIMESTAMP \(stringValue(postgresDateTimeInput(value)))"
    }

    override func intervalValue(_ value: Interval) -> String {
        "INTERVAL \(super.intervalValue(value))"
    }
    
    /// PostgreSQL SQL/JSON path operands are bindable, so the path role keeps
    /// ordinary binding. Only the direct runtime DEFAULT role is parser-restricted
    /// grammar, and only admitted value categories become parser constants.
    override func inlineUnsafeValue(
        _ value: Encodable,
        context: SQLRenderContext
    ) -> String? {
        guard let scope = SQLJSONRenderScope.resolve(context.currentScope),
              scope.role == .directRuntimeDefaultValue else {
            return nil
        }
        return SQLJSONDirectDefaultValue.postgresLiteral(value)
    }

    // returns $1 $2 $3 binding keys for PostgreSQL
    override func bindKey(_ i: Int) -> String { "$\(i)" }
    
    override var arrayStart: String { Operator.array._value + Operator.openSquareBracket._value }
    override var emptyArrayStart: String { "'" + Operator.openBrace._value }
    
    override var arrayEnd: String { Operator.closeSquareBracket._value }
    override var emptyArrayEnd: String { Operator.closeBrace._value + "'" }
}
