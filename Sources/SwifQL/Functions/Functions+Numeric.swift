//
//  Functions+Numeric.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let abs: Self = .init("abs")
    public static let avg: Self = .init("avg")
    public static let ceil: Self = .init("ceil")
    public static let ceiling: Self = .init("ceiling")
    public static let count: Self = .init("count")
    public static let div: Self = .init("div")
    public static let divide: Self = .init("divide")
    public static let exp: Self = .init("exp")
    public static let floor: Self = .init("floor")
    public static let max: Self = .init("max")
    public static let min: Self = .init("min")
    public static let mod: Self = .init("mod")
    public static let power: Self = .init("power")
    public static let random: Self = .init("random")
    public static let round: Self = .init("round")
    public static let setSeed: Self = .init("setseed")
    @available(*, deprecated, renamed: "setSeed")
    public static var setseed: Self { .setSeed }
    public static let sign: Self = .init("sign")
    public static let sqrt: Self = .init("sqrt")
    public static let sum: Self = .init("sum")
}

extension Fn {
    /// Returns the absolute value of a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/abs.php)
    public static func abs(_ number: SQLable) -> SQLable {
        build(.abs, body: number.parts)
    }
    
    /// Returns the average value of an expression
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/avg.php)
    public static func avg(_ quantity: SQLable) -> SQLable {
        build(.avg, body: quantity.parts)
    }
    
    /// Returns the smallest integer value that is greater than or equal to a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/ceil.php)
    public static func ceil(_ number: SQLable) -> SQLable {
        build(.ceil, body: number.parts)
    }
    
    /// Returns the smallest integer value that is greater than or equal to a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/ceiling.php)
    public static func ceiling(_ number: SQLable) -> SQLable {
        build(.ceiling, body: number.parts)
    }
    
    /// Returns the count of an expression
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/count.php)
    public static func count(_ expression: SQLable) -> SQLable {
        build(.count, body: expression.parts)
    }
    
    /// Used for integer division where n is divided by m and an integer value is returned
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/div.php)
    public static func div(_ n: SQLable, _ m: SQLable) -> SQLable {
        var parts: [SQLPart] = n.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: m.parts)
        return build(.div, body: parts)
    }

    /// Performs exact SQL `divide(lhs, rhs)` integer division.
    public static func divide(_ lhs: SQLable, _ rhs: SQLable) -> SQLable {
        var parts: [SQLPart] = lhs.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: rhs.parts)
        return build(.divide, body: parts)
    }
    
    /// Used for integer division where n is divided by m and an integer value is returned
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/exp.php)
    public static func exp(_ n: SQLable, _ m: SQLable) -> SQLable {
        var parts: [SQLPart] = n.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: m.parts)
        return build(.exp, body: parts)
    }

    /// Performs exact SQL `exp(value)` exponentiation.
    public static func exp(_ value: SQLable) -> SQLable {
        build(.exp, body: value.parts)
    }
    
    /// Returns the largest integer value that is equal to or less than a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/floor.php)
    public static func floor(_ number: SQLable) -> SQLable {
        build(.floor, body: number.parts)
    }
    
    /// Returns the maximum value of an expression
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/max.php)
    public static func max(_ aggregateExpression: SQLable) -> SQLable {
        build(.max, body: aggregateExpression.parts)
    }
    
    /// Returns the minimum value of an expression
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/min.php)
    public static func min(_ aggregateExpression: SQLable) -> SQLable {
        build(.min, body: aggregateExpression.parts)
    }
    
    /// Returns the remainder of n divided by m
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/mod.php)
    public static func mod(_ n: SQLable, _ m: SQLable) -> SQLable {
        var parts: [SQLPart] = n.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: m.parts)
        return build(.mod, body: parts)
    }
    
    /// Returns m raised to the nth power
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/power.php)
    public static func power(_ n: SQLable, _ m: SQLable) -> SQLable {
        var parts: [SQLPart] = n.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: m.parts)
        return build(.power, body: parts)
    }
    
    /// Random function can be used to return a random number or a random number within a range
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/random.php)
    public static func random() -> SQLable {
        build(.random, body: [])
    }
    
    /// Returns a number rounded to a certain number of decimal places
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/round.php)
    public static func round(_ number: SQLable, _ decimalPlaces: Int? = nil) -> SQLable {
        var parts: [SQLPart] = number.parts
        if let decimalPlaces = decimalPlaces {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(safe: decimalPlaces)
        }
        return build(.round, body: parts)
    }
    
    /// Can be used to set a seed for the next time that you call the random function.
    /// If you do not call setseed, PostgreSQL will use its own seed value.
    /// This may or may not be truly random.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/setseed.php)
    public static func setSeed(_ number: SQLable) -> SQLable {
        build(.setSeed, body: number.parts)
    }

    @available(*, deprecated, renamed: "setSeed(_:)")
    public static func setseed(_ number: SQLable) -> SQLable {
        setSeed(number)
    }
    
    /// Returns a value indicating the sign of a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/sign.php)
    public static func sign(_ number: SQLable) -> SQLable {
        build(.sign, body: number.parts)
    }
    
    /// Returns the square root of a number
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/sqrt.php)
    public static func sqrt(_ number: SQLable) -> SQLable {
        build(.sqrt, body: number.parts)
    }
    
    /// Returns the summed value of an expression
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/sum.php)
    public static func sum(_ aggregateExpression: SQLable) -> SQLable {
        build(.sum, body: aggregateExpression.parts)
    }
}
