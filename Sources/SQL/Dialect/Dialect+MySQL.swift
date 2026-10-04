//
//  Dialect+MySQL.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

private func mysqlDateTimeInput(_ value: DateTime) -> String {
    guard let date = value.date, let time = value.time else {
        return value.description
    }
    return "\(date.description) \(time.description)"
}

private func mysqlUnsupportedTemporalValue(_ family: String, _ value: String) -> String {
    "<mysql_unsupported_\(family):\(value)>"
}

class MySQLDialect: SQLDialect {
    override var id: String? { "mysql" }

    override func sampling(
        _ sample: SQLPartSampling,
        observingUnsafeValues observation: SQLUnsafeValueObservation
    ) -> SQLObservedParts {
        .complete(defaultSamplingParts(sample))
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

    override func identifier(_ value: String) -> String {
        "`\(value.replacingOccurrences(of: "`", with: "``"))`"
    }
    
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
        if let lastPath = keyPath.paths.last {
            if result.count > 0 {
                result.append(".")
            }
            result.append(lastPath)
        }
        return result
    }
    
    override func date(_ value: Date) -> String {
        Fn.fromUnixTime(value.timeIntervalSince1970).prepare(self).plain
    }
    
    override func pureDateValue(_ value: PureDate) -> String {
        guard let year = value.year, year >= 1000, year <= 9999 else {
            return mysqlUnsupportedTemporalValue("pure_date", value.description)
        }
        return "CAST(\(stringValue(value.description)) AS DATE)"
    }

    override func pureTimeValue(_ value: PureTime) -> String {
        let nanosecond = value.nanosecond
        guard nanosecond == 0 || nanosecond % 1_000 == 0 else {
            return mysqlUnsupportedTemporalValue("pure_time", value.description)
        }
        let precision = nanosecond == 0 ? "" : "(6)"
        return "CAST(\(stringValue(value.description)) AS TIME\(precision))"
    }

    override func dateTimeValue(_ value: DateTime) -> String {
        guard let date = value.date,
              let year = date.year,
              year >= 1000,
              year <= 9999,
              let time = value.time else {
            return mysqlUnsupportedTemporalValue("date_time", value.description)
        }

        let nanosecond = time.nanosecond
        guard nanosecond == 0 || nanosecond % 1_000 == 0 else {
            return mysqlUnsupportedTemporalValue("date_time", value.description)
        }

        let precision = nanosecond == 0 ? "" : "(6)"
        return "CAST(\(stringValue(mysqlDateTimeInput(value))) AS DATETIME\(precision))"
    }
    
    override func bindKey(_ i: Int) -> String { "?" }
    
    override var arrayStart: String { "'" }
    
    override var arrayEnd: String { "'" }
}
