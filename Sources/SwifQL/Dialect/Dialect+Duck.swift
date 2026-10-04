//
//  Dialect+Duck.swift
//

import Foundation

private func duckSamplingLiteralParts(_ value: Encodable) -> [SQLPart] {
    switch value {
    case let value as String:
        return [SQLPartSafeValue(value)]
    case let value as Int:
        return [SQLPartSafeValue(value)]
    case let value as Int8:
        return [SQLPartSafeValue(value)]
    case let value as Int16:
        return [SQLPartSafeValue(value)]
    case let value as Int32:
        return [SQLPartSafeValue(value)]
    case let value as Int64:
        return [SQLPartSafeValue(value)]
    case let value as UInt:
        return [SQLPartSafeValue(value)]
    case let value as UInt8:
        return [SQLPartSafeValue(value)]
    case let value as UInt16:
        return [SQLPartSafeValue(value)]
    case let value as UInt32:
        return [SQLPartSafeValue(value)]
    case let value as UInt64:
        return [SQLPartSafeValue(value)]
    case let value as Float:
        return [SQLPartSafeValue(value)]
    case let value as Double:
        return [SQLPartSafeValue(value)]
    case let value as Decimal:
        return [SQLPartSafeValue(value)]
    default:
        return [SQLPartOperator("<duck_sampling_argument_requires_safe_literal>")]
    }
}

private func duckSamplingLiteralParts(_ value: SQLable) -> [SQLPart] {
    switch value {
    case let value as String:
        return [SQLPartSafeValue(value)]
    case let value as Int:
        return [SQLPartSafeValue(value)]
    case let value as Int8:
        return [SQLPartSafeValue(value)]
    case let value as Int16:
        return [SQLPartSafeValue(value)]
    case let value as Int32:
        return [SQLPartSafeValue(value)]
    case let value as Int64:
        return [SQLPartSafeValue(value)]
    case let value as UInt:
        return [SQLPartSafeValue(value)]
    case let value as UInt8:
        return [SQLPartSafeValue(value)]
    case let value as UInt16:
        return [SQLPartSafeValue(value)]
    case let value as UInt32:
        return [SQLPartSafeValue(value)]
    case let value as UInt64:
        return [SQLPartSafeValue(value)]
    case let value as Float:
        return [SQLPartSafeValue(value)]
    case let value as Double:
        return [SQLPartSafeValue(value)]
    case let value as Decimal:
        return [SQLPartSafeValue(value)]
    default:
        let parts = value.parts
        if !parts.isEmpty && parts.allSatisfy({ $0 is SQLPartSafeValue }) {
            return parts
        }
        if parts.count == 1, let unsafe = parts[0] as? SQLPartUnsafeValue {
            return duckSamplingLiteralParts(unsafe.unsafeValue)
        }
        return [SQLPartOperator("<duck_sampling_argument_requires_safe_literal>")]
    }
}

private func duckObservedSamplingLiteralParts(
    _ value: SQLable,
    observation: SQLUnsafeValueObservation
) -> [SQLPart] {
    switch value {
    case let value as String:
        return [SQLPartSafeValue(value)]
    case let value as Int:
        return [SQLPartSafeValue(value)]
    case let value as Int8:
        return [SQLPartSafeValue(value)]
    case let value as Int16:
        return [SQLPartSafeValue(value)]
    case let value as Int32:
        return [SQLPartSafeValue(value)]
    case let value as Int64:
        return [SQLPartSafeValue(value)]
    case let value as UInt:
        return [SQLPartSafeValue(value)]
    case let value as UInt8:
        return [SQLPartSafeValue(value)]
    case let value as UInt16:
        return [SQLPartSafeValue(value)]
    case let value as UInt32:
        return [SQLPartSafeValue(value)]
    case let value as UInt64:
        return [SQLPartSafeValue(value)]
    case let value as Float:
        return [SQLPartSafeValue(value)]
    case let value as Double:
        return [SQLPartSafeValue(value)]
    case let value as Decimal:
        return [SQLPartSafeValue(value)]
    default:
        let parts = value.parts
        if !parts.isEmpty && parts.allSatisfy({ $0 is SQLPartSafeValue }) {
            return parts
        }
        if parts.count == 1, let unsafe = parts[0] as? SQLPartUnsafeValue {
            return [observation.notBound(unsafe)] + duckSamplingLiteralParts(unsafe.unsafeValue)
        }
        let directUnsafeMarkers = parts.compactMap { part -> SQLPart? in
            guard let unsafe = part as? SQLPartUnsafeValue else { return nil }
            return observation.notBound(unsafe)
        }
        return directUnsafeMarkers + [
            SQLPartOperator("<duck_sampling_argument_requires_safe_literal>")
        ]
    }
}

private func duckDateParts(_ value: PureDate) -> (date: String, isBC: Bool) {
    guard let year = value.year,
          let month = value.month,
          let day = value.day else {
        return (value.description, false)
    }

    guard year <= 0 else {
        if year <= 9999 {
            return (value.description, false)
        }
        func padded(_ component: Int) -> String {
            let digits = String(component)
            return String(repeating: "0", count: max(0, 2 - digits.count)) + digits
        }
        return ("\(year)-\(padded(month))-\(padded(day))", false)
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

private func duckDateInput(_ value: PureDate) -> String {
    let parts = duckDateParts(value)
    return parts.date + (parts.isBC ? " (BC)" : "")
}

private func duckDateTimeInput(_ value: DateTime) -> String {
    guard let date = value.date, let time = value.time else {
        return value.description
    }
    let parts = duckDateParts(date)
    return "\(parts.date)" + (parts.isBC ? " (BC)" : "") + " \(time.description)"
}

class DuckDialect: SQLDialect {
    private static let unqualifiedKeyPathScopes: Set<SQLRenderScope> = [
        .simplifiedPivotOn,
        .simplifiedPivotUsing,
        .simplifiedPivotGroupBy,
        .simplifiedPivotOrderBy,
        .simplifiedUnpivotOrderBy
    ]

    override var id: String? { "duckdb" }

    override var hybridRepresentationKey: SQLHybridRepresentationKey? { .duck }

    override func hybridOperator(_ hybrid: SQLHybridOperator) -> SQLPartOperator {
        hybrid.representation(for: .duck)
            ?? SQLPartOperator("<duck_hybrid_operator_requires_explicit_duck_branch>")
    }

    override func sampling(_ sample: SQLPartSampling) -> [SQLPart] {
        sample.renderedParts(
            argumentParts: sample.arguments.map { duckSamplingLiteralParts($0.value) },
            seedParts: sample.seed.map { duckSamplingLiteralParts($0.value) },
            repeatabilityParts: sample.repeatability.map { duckSamplingLiteralParts($0.value) }
        )
    }

    override func sampling(
        _ sample: SQLPartSampling,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .complete(sample.renderedParts(
            argumentParts: sample.arguments.map {
                duckObservedSamplingLiteralParts($0.value, observation: observation)
            },
            seedParts: sample.seed.map {
                duckObservedSamplingLiteralParts($0.value, observation: observation)
            },
            repeatabilityParts: sample.repeatability.map {
                duckObservedSamplingLiteralParts($0.value, observation: observation)
            }
        ))
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

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func quotedIdentifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    override func schemaName(_ value: String) -> String { quotedIdentifier(value) }

    override func identifier(_ value: String) -> String { quotedIdentifier(value) }

    override func catalogName(_ value: String) -> String { quotedIdentifier(value) }

    override func tableName(_ value: String) -> String { quotedIdentifier(value) }

    override func alias(_ value: String) -> String { quotedIdentifier(value) }

    override func column(_ value: String) -> String { quotedIdentifier(value) }

    override func stringValue(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
    }

    override func jsonField(_ value: String) -> String { stringValue(value) }

    private func shouldUnqualifyKeyPath(_ context: SQLRenderContext) -> Bool {
        context.scopes.contains { Self.unqualifiedKeyPathScopes.contains($0) }
    }

    private func renderKeyPath(
        _ keyPath: SQLPartKeyPath,
        qualified: Bool
    ) -> String {
        var result = ""
        if qualified {
            if let schema = keyPath.schema {
                result.append(schemaName(schema))
            }
            if let table = keyPath.table {
                if result.count > 0 {
                    result.append(".")
                }
                result.append(tableName(table))
            }
        }
        for (i, value) in keyPath.paths.enumerated() {
            if i == 0 {
                if result.count > 0 {
                    result.append(".")
                }
                result.append(column(value))
            } else {
                if keyPath.asText, i == keyPath.paths.count - 1 {
                    result.append("->>")
                } else {
                    result.append("->")
                }
                result.append(jsonField(value))
            }
        }
        if keyPath.paths.count > 1 {
            return "(\(result))"
        }
        return result
    }

    override func keyPath(_ keyPath: SQLPartKeyPath) -> String {
        renderKeyPath(keyPath, qualified: true)
    }

    override func keyPath(
        _ keyPath: SQLPartKeyPath,
        context: SQLRenderContext
    ) -> String {
        renderKeyPath(
            keyPath,
            qualified: !shouldUnqualifyKeyPath(context)
        )
    }

    override func date(_ value: Date) -> String {
        let microsecondsSinceEpoch = Int64((value.timeIntervalSince1970 * 1_000_000).rounded())
        var normalizedDate = Date(timeIntervalSince1970: Double(microsecondsSinceEpoch) / 1_000_000)
        var components = utcCalendar.dateComponents(in: utcCalendar.timeZone, from: normalizedDate)
        var second = utcCalendar.date(from: DateComponents(
            calendar: utcCalendar,
            timeZone: utcCalendar.timeZone,
            year: components.year,
            month: components.month,
            day: components.day,
            hour: components.hour,
            minute: components.minute,
            second: components.second
        ))!
        var microseconds = Int((normalizedDate.timeIntervalSince(second) * 1_000_000).rounded())
        if microseconds >= 1_000_000 {
            normalizedDate = second.addingTimeInterval(1)
            components = utcCalendar.dateComponents(in: utcCalendar.timeZone, from: normalizedDate)
            second = utcCalendar.date(from: DateComponents(
                calendar: utcCalendar,
                timeZone: utcCalendar.timeZone,
                year: components.year,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: components.minute,
                second: components.second
            ))!
            microseconds = 0
        }

        func padded(_ value: Int, to length: Int) -> String {
            let string = String(value)
            return String(repeating: "0", count: max(0, length - string.count)) + string
        }

        return "TIMESTAMPTZ '\(padded(components.year!, to: 4))-\(padded(components.month!, to: 2))-\(padded(components.day!, to: 2)) \(padded(components.hour!, to: 2)):\(padded(components.minute!, to: 2)):\(padded(components.second!, to: 2)).\(padded(microseconds, to: 6))+00:00'"
    }

    override func pureDateValue(_ value: PureDate) -> String {
        "DATE \(stringValue(duckDateInput(value)))"
    }

    override func pureTimeValue(_ value: PureTime) -> String {
        "CAST(\(stringValue(value.description)) AS TIME_NS)"
    }

    override func dateTimeValue(_ value: DateTime) -> String {
        "CAST(\(stringValue(duckDateTimeInput(value))) AS TIMESTAMP_NS)"
    }

    override func intervalValue(_ value: Interval) -> String {
        guard value.isFinite else {
            // DuckDB has no native shared Interval infinity state; preserve
            // the explicit special value as a rejected, non-finite fallback.
            return super.intervalValue(value)
        }
        return "INTERVAL \(super.intervalValue(value))"
    }

    override func bindKey(_ i: Int) -> String { "$\(i)" }

    override func inlineUnsafeValue(
        _ value: Encodable,
        context: SQLRenderContext
    ) -> String? {
        guard context.contains(.starPattern) else { return nil }
        return safeValue(value)
    }

    override var arrayStart: String { "[" }

    override var arrayEnd: String { "]" }
}
