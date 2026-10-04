//
//  Functions+Window.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let rowNumber: Self = .init("row_number")
    @available(*, deprecated, renamed: "rowNumber")
    public static var row_number: Self { .rowNumber }
    public static let rank: Self = .init("rank")
    public static let denseRank: Self = .init("dense_rank")
    @available(*, deprecated, renamed: "denseRank")
    public static var dense_rank: Self { .denseRank }
    public static let percentRank: Self = .init("percent_rank")
    @available(*, deprecated, renamed: "percentRank")
    public static var percent_rank: Self { .percentRank }
    public static let cumeDist: Self = .init("cume_dist")
    @available(*, deprecated, renamed: "cumeDist")
    public static var cume_dist: Self { .cumeDist }
    public static let nTile: Self = .init("ntile")
    @available(*, deprecated, renamed: "nTile")
    public static var ntile: Self { .nTile }
    public static let lag: Self = .init("lag")
    public static let lead: Self = .init("lead")
    public static let firstValue: Self = .init("first_value")
    @available(*, deprecated, renamed: "firstValue")
    public static var first_value: Self { .firstValue }
    public static let lastValue: Self = .init("last_value")
    @available(*, deprecated, renamed: "lastValue")
    public static var last_value: Self { .lastValue }
    public static let nthValue: Self = .init("nth_value")
    @available(*, deprecated, renamed: "nthValue")
    public static var nth_value: Self { .nthValue }
}

extension Fn {
    /// Number of the current row within its partition, counting from 1
    ///
    /// # Example
    /// ```swift
    /// Fn.rowNumber()
    /// ```
    /// # Result
    /// ```
    /// row_number()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func rowNumber() -> SQLable {
        build(.rowNumber, body: [])
    }

    @available(*, deprecated, renamed: "rowNumber()")
    public static func row_number() -> SQLable {
        rowNumber()
    }
    
    /// Rank of the current row with gaps
    /// same as row_number of its first peer
    ///
    /// # Example
    /// ```swift
    /// Fn.rank()
    /// ```
    /// # Result
    /// ```
    /// rank()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func rank() -> SQLable {
        build(.rank, body: [])
    }
    
    /// Rank of the current row without gaps
    /// this function counts peer groups
    ///
    /// # Example
    /// ```swift
    /// Fn.denseRank()
    /// ```
    /// # Result
    /// ```
    /// dense_rank()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func denseRank() -> SQLable {
        build(.denseRank, body: [])
    }

    @available(*, deprecated, renamed: "denseRank()")
    public static func dense_rank() -> SQLable {
        denseRank()
    }
    
    /// Relative rank of the current row: (rank - 1) / (total partition rows - 1)
    ///
    /// # Example
    /// ```swift
    /// Fn.percentRank()
    /// ```
    /// # Result
    /// ```
    /// percent_rank()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func percentRank() -> SQLable {
        build(.percentRank, body: [])
    }

    @available(*, deprecated, renamed: "percentRank()")
    public static func percent_rank() -> SQLable {
        percentRank()
    }
    
    /// Cumulative distribution: (number of partition rows preceding or peer with current row) / total partition rows
    ///
    /// # Example
    /// ```swift
    /// Fn.cumeDist()
    /// ```
    /// # Result
    /// ```
    /// cume_dist()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func cumeDist() -> SQLable {
        build(.cumeDist, body: [])
    }

    @available(*, deprecated, renamed: "cumeDist()")
    public static func cume_dist() -> SQLable {
        cumeDist()
    }
    
    /// Integer ranging from 1 to the argument value, dividing the partition as equally as possible
    ///
    /// # Example
    /// ```swift
    /// Fn.nTile()
    /// ```
    /// # Result
    /// ```
    /// ntile()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func nTile(_ num_buckets: SQLable) -> SQLable {
        build(.nTile, body: num_buckets.parts)
    }

    @available(*, deprecated, renamed: "nTile(_:)")
    public static func ntile(_ num_buckets: SQLable) -> SQLable {
        nTile(num_buckets)
    }
    
    /// Returns `value` evaluated at the row that is `offset` rows before the current row within the partition
    /// if there is no such row, instead return `default` (which must be of the same type as `value`).
    /// Both `offset` and `default` are evaluated with respect to the current row.
    /// If omitted, `offset` defaults to 1 and `default` to null
    ///
    /// # Example
    /// ```swift
    /// Fn.lag()
    /// ```
    /// # Result
    /// ```
    /// lag()
    /// ```
    /// [Examples →](https://www.postgresqltutorial.com/postgresql-lag-function/)
    ///
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func lag(_ value: SQLable, _ offset: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = value.parts
        if let offset = offset {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: offset.parts)
        }
        return build(.lag, body: parts)
    }
    
    /// Returns value evaluated at the row that is `offset` rows after the current row within the partition
    /// if there is no such row, instead return `default` (which must be of the same type as `value`).
    /// Both `offset` and `default` are evaluated with respect to the current row.
    /// If omitted, `offset` defaults to 1 and `default` to null
    ///
    /// # Example
    /// ```swift
    /// Fn.lead()
    /// ```
    /// # Result
    /// ```
    /// lead()
    /// ```
    /// [Examples →](https://www.postgresqltutorial.com/postgresql-lead-function/)
    ///
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func lead(_ value: SQLable, _ offset: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = value.parts
        if let offset = offset {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: offset.parts)
        }
        return build(.lead, body: parts)
    }
    
    /// Returns value evaluated at the row that is the first row of the window frame
    ///
    /// # Example
    /// ```swift
    /// Fn.firstValue()
    /// ```
    /// # Result
    /// ```
    /// first_value()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func firstValue(_ value: SQLable) -> SQLable {
        build(.firstValue, body: value.parts)
    }

    @available(*, deprecated, renamed: "firstValue(_:)")
    public static func first_value(_ value: SQLable) -> SQLable {
        firstValue(value)
    }
    
    /// Returns value evaluated at the row that is the last row of the window frame
    ///
    /// # Example
    /// ```swift
    /// Fn.lastValue()
    /// ```
    /// # Result
    /// ```
    /// last_value()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func lastValue(_ value: SQLable) -> SQLable {
        build(.lastValue, body: value.parts)
    }

    @available(*, deprecated, renamed: "lastValue(_:)")
    public static func last_value(_ value: SQLable) -> SQLable {
        lastValue(value)
    }
    
    /// Returns `value` evaluated at the row that is the `nth` row of the window frame (counting from 1)
    /// null if no such row
    ///
    /// # Example
    /// ```swift
    /// Fn.nthValue()
    /// ```
    /// # Result
    /// ```
    /// nth_value()
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-window.html)
    public static func nthValue(_ value: SQLable, _ nth: SQLable) -> SQLable {
        var parts: [SQLPart] = value.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: nth.parts)
        return build(.nthValue, body: parts)
    }

    @available(*, deprecated, renamed: "nthValue(_:_:)")
    public static func nth_value(_ value: SQLable, _ nth: SQLable) -> SQLable {
        nthValue(value, nth)
    }
}
