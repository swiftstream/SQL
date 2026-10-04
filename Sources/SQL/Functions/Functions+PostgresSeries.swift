//
//  Functions+PostgresSeries.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let generateSeries: Self = .init("generate_series")
    @available(*, deprecated, renamed: "generateSeries")
    public static var generate_series: Self { .generateSeries }
}

extension Fn {
    /// Generate series
    /// # Example
    /// ```swift
    /// Fn.generateSeries(1, 4)
    /// Fn.generateSeries(1, 4, 2)
    /// Fn.generateSeries('2019-10-01', '2019-10-04', '1 day')
    /// ```
    /// # Result
    /// ```
    /// 1, 2, 3, 4
    /// 1, 3
    /// 2019-10-01, 2019-10-02, 2019-10-03, 2019-10-04
    /// ```
    ///
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-srf.html)
    public static func generateSeries(_ start: SQLable, _ stop: SQLable, _ step: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = start.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: stop.parts)
        if let step = step {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: step.parts)
        }
        return build(.generateSeries, body: parts)
    }

    @available(*, deprecated, renamed: "generateSeries(_:_:_:)")
    public static func generate_series(_ start: SQLable, _ stop: SQLable, _ step: SQLable? = nil) -> SQLable {
        generateSeries(start, stop, step)
    }
}
