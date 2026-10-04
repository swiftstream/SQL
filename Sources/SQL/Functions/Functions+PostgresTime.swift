//
//  Functions+PostgresTime.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let age: Self = .init("age")
    public static let clockTimestamp: Self = .init("clock_timestamp")
    @available(*, deprecated, renamed: "clockTimestamp")
    public static var clock_timestamp: Self { .clockTimestamp }
    public static let currentDate: Self = .init("current_date")
    @available(*, deprecated, renamed: "currentDate")
    public static var current_date: Self { .currentDate }
    public static let currentTime: Self = .init("current_time")
    @available(*, deprecated, renamed: "currentTime")
    public static var current_time: Self { .currentTime }
    public static let currentTimestamp: Self = .init("current_timestamp")
    @available(*, deprecated, renamed: "currentTimestamp")
    public static var current_timestamp: Self { .currentTimestamp }
    public static let datePart: Self = .init("date_part")
    @available(*, deprecated, renamed: "datePart")
    public static var date_part: Self { .datePart }
    public static let dateTrunc: Self = .init("date_trunc")
    @available(*, deprecated, renamed: "dateTrunc")
    public static var date_trunc: Self { .dateTrunc }
    public static let extract: Self = .init("extract")
    public static let isFinite: Self = .init("isfinite")
    @available(*, deprecated, renamed: "isFinite")
    public static var isfinite: Self { .isFinite }
    public static let justifyDays: Self = .init("justify_days")
    @available(*, deprecated, renamed: "justifyDays")
    public static var justify_days: Self { .justifyDays }
    public static let justifyHours: Self = .init("justify_hours")
    @available(*, deprecated, renamed: "justifyHours")
    public static var justify_hours: Self { .justifyHours }
    public static let justifyInterval: Self = .init("justify_interval")
    @available(*, deprecated, renamed: "justifyInterval")
    public static var justify_interval: Self { .justifyInterval }
    public static let localTime: Self = .init("localtime")
    @available(*, deprecated, renamed: "localTime")
    public static var localtime: Self { .localTime }
    public static let localTimestamp: Self = .init("localtimestamp")
    @available(*, deprecated, renamed: "localTimestamp")
    public static var localtimestamp: Self { .localTimestamp }
    public static let makeDate: Self = .init("make_date")
    @available(*, deprecated, renamed: "makeDate")
    public static var make_date: Self { .makeDate }
    public static let makeInterval: Self = .init("make_interval")
    @available(*, deprecated, renamed: "makeInterval")
    public static var make_interval: Self { .makeInterval }
    public static let makeTime: Self = .init("make_time")
    @available(*, deprecated, renamed: "makeTime")
    public static var make_time: Self { .makeTime }
    public static let makeTimestamp: Self = .init("make_timestamp")
    @available(*, deprecated, renamed: "makeTimestamp")
    public static var make_timestamp: Self { .makeTimestamp }
    public static let makeTimestampTZ: Self = .init("make_timestamptz")
    @available(*, deprecated, renamed: "makeTimestampTZ")
    public static var make_timestamptz: Self { .makeTimestampTZ }
    public static let now: Self = .init("now")
    public static let statementTimestamp: Self = .init("statement_timestamp")
    @available(*, deprecated, renamed: "statementTimestamp")
    public static var statement_timestamp: Self { .statementTimestamp }
    public static let timeOfDay: Self = .init("timeofday")
    @available(*, deprecated, renamed: "timeOfDay")
    public static var timeofday: Self { .timeOfDay }
    public static let transactionTimestamp: Self = .init("transaction_timestamp")
    @available(*, deprecated, renamed: "transactionTimestamp")
    public static var transaction_timestamp: Self { .transactionTimestamp }
    public static let toTimestamp: Self = .init("to_timestamp")
    @available(*, deprecated, renamed: "toTimestamp")
    public static var to_timestamp: Self { .toTimestamp }
}

extension Fn {
    /// Subtract arguments, producing a “symbolic” result that uses years and months, rather than just days
    /// # Example
    /// ```swift
    /// Fn.age("2001-04-10" => .timestamp, "1957-06-13" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 43 years 9 mons 27 days
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func age(_ timestamp1: SQLable, _ timestamp2: SQLable) -> SQLable {
        var parts: [SQLPart] = timestamp1.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: timestamp2.parts)
        return build(.age, body: parts)
    }
    
    /// Subtract from current_date (at midnight)
    /// # Example
    /// ```swift
    /// Fn.age("2001-04-10" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 43 years 8 mons 3 days
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func age(_ timestamp1: SQLable) -> SQLable {
        build(.age, body: timestamp1.parts)
    }
    
    /// Current date and time (changes during statement execution)
    /// # Example
    /// ```swift
    /// Fn.clockTimestamp()
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT)
    public static func clockTimestamp() -> SQLable {
        build(.clockTimestamp, body: [])
    }

    @available(*, deprecated, renamed: "clockTimestamp()")
    public static func clock_timestamp() -> SQLable {
        clockTimestamp()
    }
    
    /// Current date
    /// # Example
    /// ```swift
    /// Fn.currentDate
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT)
    public static var currentDate: SQLable {
        SQLableParts(parts: Name.currentDate.part)
    }

    @available(*, deprecated, renamed: "currentDate")
    public static var current_date: SQLable {
        currentDate
    }
    
    /// Current time of day
    /// # Example
    /// ```swift
    /// Fn.currentTime
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT)
    public static func currentTime(_ aggregateExpression: SQLable) -> SQLable {
        SQLableParts(parts: Name.currentTime.part)
    }

    @available(*, deprecated, renamed: "currentTime(_:)")
    public static func current_time(_ aggregateExpression: SQLable) -> SQLable {
        currentTime(aggregateExpression)
    }
    
    /// Current date and time (start of current transaction)
    /// # Example
    /// ```swift
    /// Fn.currentTimestamp
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT)
    public static func currentTimestamp(_ aggregateExpression: SQLable) -> SQLable {
        SQLableParts(parts: Name.currentTimestamp.part)
    }

    @available(*, deprecated, renamed: "currentTimestamp(_:)")
    public static func current_timestamp(_ aggregateExpression: SQLable) -> SQLable {
        currentTimestamp(aggregateExpression)
    }
    
    /// Get subfield (equivalent to extract)
    /// # Example with timestamp
    /// ```swift
    /// Fn.datePart("hour", "2001-02-16 20:38:40" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 20
    /// ```
    /// # Example with interval
    /// ```swift
    /// Fn.datePart("month", "2 years 3 months" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 3
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT)
    public static func datePart(_ text: SQLable, _ value: SQLable) -> SQLable {
        var parts: [SQLPart] = text.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: value.parts)
        return build(.datePart, body: parts)
    }

    @available(*, deprecated, renamed: "datePart(_:_:)")
    public static func date_part(_ text: SQLable, _ value: SQLable) -> SQLable {
        datePart(text, value)
    }
    
    /// Truncate to specified precision
    /// # Example with timestamp
    /// ```swift
    /// Fn.dateTrunc("hour", "2001-02-16 20:38:40" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 2001-02-16 20:00:00
    /// ```
    /// # Example with interval
    /// ```swift
    /// Fn.dateTrunc("hour", "2 days 3 hours 40 minutes" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 2 days 03:00:00
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC)
    public static func dateTrunc(_ text: SQLable, _ value: SQLable) -> SQLable {
        var parts: [SQLPart] = text.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: value.parts)
        return build(.dateTrunc, body: parts)
    }

    @available(*, deprecated, renamed: "dateTrunc(_:_:)")
    public static func date_trunc(_ text: SQLable, _ value: SQLable) -> SQLable {
        dateTrunc(text, value)
    }
    
    /// Get subfield
    /// # Example with timestamp
    /// ```swift
    /// Fn.extract(.hour, "2001-02-16 20:38:40" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 20
    /// ```
    /// # Example with interval
    /// ```swift
    /// Fn.extract(.month, "2 years 3 months" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 3
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT)
    public static func extract(_ field: ExtractFieldValue, from value: SQLable) -> SQLable {
        var parts: [SQLPart] = []
        parts.append(safe: field.value)
        parts.append(o: .space)
        parts.append(o: .from)
        parts.append(o: .space)
        parts.append(contentsOf: value.parts)
        return build(.extract, body: parts)
    }
    
    /// Get subfield
    /// # Example with timestamp
    /// ```swift
    /// Fn.extract("hour", "2001-02-16 20:38:40" => .timestamp)
    /// ```
    /// # Result
    /// ```
    /// 20
    /// ```
    /// # Example with interval
    /// ```swift
    /// Fn.extract("month", "2 years 3 months" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 3
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT)
    public static func extract(_ field: SQLable, from value: SQLable) -> SQLable {
        var parts: [SQLPart] = field.parts
        parts.append(o: .space)
        parts.append(o: .from)
        parts.append(o: .space)
        parts.append(contentsOf: value.parts)
        return build(.extract, body: parts)
    }
    
    /// Test for finite date (not +/-infinity)
    /// # Example
    /// ```swift
    /// Fn.isFinite("4 hours" => .interval)
    /// ```
    /// # Result
    /// ```
    /// true
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func isFinite(_ interval: SQLable) -> SQLable {
        build(.isFinite, body: interval.parts)
    }

    @available(*, deprecated, renamed: "isFinite(_:)")
    public static func isfinite(_ interval: SQLable) -> SQLable {
        isFinite(interval)
    }
    
    /// Adjust interval so 30-day time periods are represented as months
    /// # Example
    /// ```swift
    /// Fn.justifyDays("35 days" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 1 mon 5 days
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func justifyDays(_ interval: SQLable) -> SQLable {
        build(.justifyDays, body: interval.parts)
    }

    @available(*, deprecated, renamed: "justifyDays(_:)")
    public static func justify_days(_ interval: SQLable) -> SQLable {
        justifyDays(interval)
    }
    
    /// Adjust interval so 24-hour time periods are represented as days
    /// # Example
    /// ```swift
    /// Fn.justifyHours("27 hours" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 1 day 03:00:00
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func justifyHours(_ interval: SQLable) -> SQLable {
        build(.justifyHours, body: interval.parts)
    }

    @available(*, deprecated, renamed: "justifyHours(_:)")
    public static func justify_hours(_ interval: SQLable) -> SQLable {
        justifyHours(interval)
    }
    
    /// Adjust interval using justify_days and justify_hours, with additional sign adjustments
    /// # Example
    /// ```swift
    /// Fn.justifyInterval("1 mon -1 hour" => .interval)
    /// ```
    /// # Result
    /// ```
    /// 29 days 23:00:00
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func justifyInterval(_ interval: SQLable) -> SQLable {
        build(.justifyInterval, body: interval.parts)
    }

    @available(*, deprecated, renamed: "justifyInterval(_:)")
    public static func justify_interval(_ interval: SQLable) -> SQLable {
        justifyInterval(interval)
    }
    
    /// Current time of day
    /// # Example
    /// ```swift
    /// Fn.localTime
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static var localTime: SQLable {
        SQLableParts(parts: Name.localTime.part)
    }

    @available(*, deprecated, renamed: "localTime")
    public static var localtime: SQLable {
        localTime
    }
    
    /// Current date and time (start of current transaction)
    /// # Example
    /// ```swift
    /// Fn.localTimestamp
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static var localTimestamp: SQLable {
        SQLableParts(parts: Name.localTimestamp.part)
    }

    @available(*, deprecated, renamed: "localTimestamp")
    public static var localtimestamp: SQLable {
        localTimestamp
    }
    
    /// Create date from year, month and day fields
    /// # Example
    /// ```swift
    /// Fn.makeDate(2013, 7, 15)
    /// ```
    /// # Result
    /// ```
    /// 2013-07-15
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func makeDate(_ year: SQLable, _ month: SQLable, _ day: SQLable) -> SQLable {
        var parts: [SQLPart] = year.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: month.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: day.parts)
        return build(.makeDate, body: parts)
    }

    @available(*, deprecated, renamed: "makeDate(_:_:_:)")
    public static func make_date(_ year: SQLable, _ month: SQLable, _ day: SQLable) -> SQLable {
        makeDate(year, month, day)
    }
    
    /// Create interval from years, months, weeks, days, hours, minutes and seconds fields
    /// # Example
    /// ```swift
    /// Fn.makeInterval(days: 10)
    /// ```
    /// # Result
    /// ```
    /// 10 days
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func makeInterval(years: SQLable? = nil,
                                                   months: SQLable? = nil,
                                                   weeks: SQLable? = nil,
                                                   days: SQLable? = nil,
                                                   hours: SQLable? = nil,
                                                   mins: SQLable? = nil,
                                                   secs: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = []
        if let years = years {
            parts.append(o: .custom("years => "))
            if let number = years as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: years.parts)
            }
        }
        if let months = months {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("months => "))
            if let number = months as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: months.parts)
            }
        }
        if let weeks = weeks {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("weeks => "))
            if let number = weeks as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: weeks.parts)
            }
        }
        if let days = days {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("days => "))
            if let number = days as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: days.parts)
            }
        }
        if let hours = hours {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("hours => "))
            if let number = hours as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: hours.parts)
            }
        }
        if let mins = mins {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("mins => "))
            if let number = mins as? Int {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: mins.parts)
            }
        }
        if let secs = secs {
            if parts.count > 0 { parts.append(o: .comma, .space) }
            parts.append(o: .custom("secs => "))
            if let number = secs as? Int {
                parts.append(o: .custom("\(number)"))
            } else if let number = secs as? Double {
                parts.append(o: .custom("\(number)"))
            } else {
                parts.append(contentsOf: secs.parts)
            }
        }
        return build(.makeInterval, body: parts)
    }

    @available(*, deprecated, renamed: "makeInterval(years:months:weeks:days:hours:mins:secs:)")
    public static func make_interval(years: SQLable? = nil,
                                                   months: SQLable? = nil,
                                                   weeks: SQLable? = nil,
                                                   days: SQLable? = nil,
                                                   hours: SQLable? = nil,
                                                   mins: SQLable? = nil,
                                                   secs: SQLable? = nil) -> SQLable {
        makeInterval(years: years, months: months, weeks: weeks, days: days, hours: hours, mins: mins, secs: secs)
    }
    
    /// Create time from hour, minute and seconds fields
    /// # Example
    /// ```swift
    /// Fn.makeTime(8, 15, 23.5)
    /// ```
    /// # Result
    /// ```
    /// 08:15:23.5
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func makeTime(_ hour: SQLable, _ min: SQLable, _ sec: SQLable) -> SQLable {
        var parts: [SQLPart] = hour.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: min.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: sec.parts)
        return build(.makeTime, body: parts)
    }

    @available(*, deprecated, renamed: "makeTime(_:_:_:)")
    public static func make_time(_ hour: SQLable, _ min: SQLable, _ sec: SQLable) -> SQLable {
        makeTime(hour, min, sec)
    }
    
    /// Create timestamp from year, month, day, hour, minute and seconds fields
    /// # Example
    /// ```swift
    /// Fn.makeTimestamp(2013, 7, 15, 8, 15, 23.5)
    /// ```
    /// # Result
    /// ```
    /// 2013-07-15 08:15:23.5
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func makeTimestamp(_ year: SQLable,
                                                       _ month: SQLable,
                                                       _ day: SQLable,
                                                       _ hour: SQLable,
                                                       _ min: SQLable,
                                                       _ sec: SQLable) -> SQLable {
        var parts: [SQLPart] = year.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: month.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: day.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: hour.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: min.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: sec.parts)
        return build(.makeTimestamp, body: parts)
    }

    @available(*, deprecated, renamed: "makeTimestamp(_:_:_:_:_:_:)")
    public static func make_timestamp(_ year: SQLable,
                                                       _ month: SQLable,
                                                       _ day: SQLable,
                                                       _ hour: SQLable,
                                                       _ min: SQLable,
                                                       _ sec: SQLable) -> SQLable {
        makeTimestamp(year, month, day, hour, min, sec)
    }
    
    /// Create timestamp with time zone from year, month, day, hour, minute and seconds fields;
    /// if timezone is not specified, the current time zone is used
    /// # Example
    /// ```swift
    /// Fn.makeTimestampTZ(2013, 7, 15, 8, 15, 23.5)
    /// ```
    /// # Result
    /// ```
    /// 2013-07-15 08:15:23.5+01
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func makeTimestampTZ(_ year: SQLable,
                                                          _ month: SQLable,
                                                          _ day: SQLable,
                                                          _ hour: SQLable,
                                                          _ min: SQLable,
                                                          _ sec: SQLable,
                                                          _ timezone: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = year.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: month.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: day.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: hour.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: min.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: sec.parts)
        if let timezone = timezone {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: timezone.parts)
        }
        return build(.makeTimestampTZ, body: parts)
    }

    @available(*, deprecated, renamed: "makeTimestampTZ(_:_:_:_:_:_:_:)")
    public static func make_timestamptz(_ year: SQLable,
                                                          _ month: SQLable,
                                                          _ day: SQLable,
                                                          _ hour: SQLable,
                                                          _ min: SQLable,
                                                          _ sec: SQLable,
                                                          _ timezone: SQLable? = nil) -> SQLable {
        makeTimestampTZ(year, month, day, hour, min, sec, timezone)
    }
    
    /// Current date and time (start of current transaction)
    /// # Example
    /// ```swift
    /// Fn.now()
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func now() -> SQLable {
        build(.now, body: [])
    }
    
    /// Current date and time (start of current statement)
    /// # Example
    /// ```swift
    /// Fn.statementTimestamp()
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func statementTimestamp() -> SQLable {
        build(.statementTimestamp, body: [])
    }

    @available(*, deprecated, renamed: "statementTimestamp()")
    public static func statement_timestamp() -> SQLable {
        statementTimestamp()
    }
    
    /// Current date and time (like clock_timestamp, but as a text string)
    /// # Example
    /// ```swift
    /// Fn.timeOfDay()
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func timeOfDay() -> SQLable {
        build(.timeOfDay, body: [])
    }

    @available(*, deprecated, renamed: "timeOfDay()")
    public static func timeofday() -> SQLable {
        timeOfDay()
    }
    
    /// Current date and time (start of current transaction)
    /// # Example
    /// ```swift
    /// Fn.transactionTimestamp()
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func transactionTimestamp() -> SQLable {
        build(.transactionTimestamp, body: [])
    }

    @available(*, deprecated, renamed: "transactionTimestamp()")
    public static func transaction_timestamp() -> SQLable {
        transactionTimestamp()
    }
    
    /// Convert Unix epoch (seconds since 1970-01-01 00:00:00+00) to timestamp
    /// # Example
    /// ```swift
    /// Fn.toTimestamp(1284352323)
    /// ```
    /// # Result
    /// ```
    /// 2010-09-13 04:32:03+00
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-datetime.html)
    public static func toTimestamp(_ value: SQLable) -> SQLable {
        build(.toTimestamp, body: value.parts)
    }

    @available(*, deprecated, renamed: "toTimestamp(_:)")
    public static func to_timestamp(_ value: SQLable) -> SQLable {
        toTimestamp(value)
    }
}
