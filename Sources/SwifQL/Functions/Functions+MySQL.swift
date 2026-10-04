//
//  Functions+MySQL.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let fromUnixTime: Self = .init("FROM_UNIXTIME")
    @available(*, deprecated, renamed: "fromUnixTime")
    public static var from_unixtime: Self { .fromUnixTime }
    public static let dateFormat: Self = .init("DATE_FORMAT")
    @available(*, deprecated, renamed: "dateFormat")
    public static var date_format: Self { .dateFormat }
}

extension Fn {
    public static func fromUnixTime(_ timeinterval: SQLable, _ format: String? = nil) -> SQLable {
        var parts: [SQLPart] = timeinterval.parts
        if let format = format {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(o: .custom(format.singleQuotted))
        }
        return build(.fromUnixTime, body: parts)
    }

    @available(*, deprecated, renamed: "fromUnixTime(_:_:)")
    public static func from_unixtime(_ timeinterval: SQLable, _ format: String? = nil) -> SQLable {
        fromUnixTime(timeinterval, format)
    }

    /// Formats the date value according to the format string.
    /// # Example
    /// ```swift
    /// Fn.dateFormat(\User.createdAt, "%y-%m")
    /// ```
    /// # Result
    /// ```
    /// date_format(User.createdAt, '%y-%m')
    /// ```
    /// [Learn more →](https://dev.mysql.com/doc/refman/5.7/en/date-and-time-functions.html#function_date-format)
    /// [Learn more →](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_date-format)
    public static func dateFormat(_ datetime: SQLable, _ format: String) -> SQLable {
        var parts: [SQLPart] = datetime.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(o: .custom(format.singleQuotted))
        return build(.dateFormat, body: parts)
    }

    @available(*, deprecated, renamed: "dateFormat(_:_:)")
    public static func date_format(_ datetime: SQLable, _ format: String) -> SQLable {
        dateFormat(datetime, format)
    }
}
