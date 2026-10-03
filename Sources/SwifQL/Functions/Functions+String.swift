//
//  Functions+String.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let bitLength: Self = .init("bit_length")
    @available(*, deprecated, renamed: "bitLength")
    public static var bit_length: Self { .bitLength }
    public static let bTrim: Self = .init("btrim")
    @available(*, deprecated, renamed: "bTrim")
    public static var btrim: Self { .bTrim }
    public static let charLength: Self = .init("char_length")
    @available(*, deprecated, renamed: "charLength")
    public static var char_length: Self { .charLength }
    public static let characterLength: Self = .init("character_length")
    @available(*, deprecated, renamed: "characterLength")
    public static var character_length: Self { .characterLength }
    public static let initCap: Self = .init("initcap")
    @available(*, deprecated, renamed: "initCap")
    public static var initcap: Self { .initCap }
    public static let concat: Self = .init("concat")
    public static let concatWS: Self = .init("concat_ws")
    @available(*, deprecated, renamed: "concatWS")
    public static var concat_ws: Self { .concatWS }
    public static let arrayLength: Self = .init("array_length")
    @available(*, deprecated, renamed: "arrayLength")
    public static var array_length: Self { .arrayLength }
    public static let length: Self = .init("length")
    public static let lower: Self = .init("lower")
    public static let lPad: Self = .init("lpad")
    @available(*, deprecated, renamed: "lPad")
    public static var lpad: Self { .lPad }
    public static let lTrim: Self = .init("ltrim")
    @available(*, deprecated, renamed: "lTrim")
    public static var ltrim: Self { .lTrim }
    public static let position: Self = .init("position")
    public static let `repeat`: Self = .init("repeat")
    public static let replace: Self = .init("replace")
    public static let rPad: Self = .init("rpad")
    @available(*, deprecated, renamed: "rPad")
    public static var rpad: Self { .rPad }
    public static let rTrim: Self = .init("rtrim")
    @available(*, deprecated, renamed: "rTrim")
    public static var rtrim: Self { .rTrim }
    public static let strPos: Self = .init("strpos")
    @available(*, deprecated, renamed: "strPos")
    public static var strpos: Self { .strPos }
    public static let substring: Self = .init("substring")
    public static let translate: Self = .init("translate")
    public static let trim: Self = .init("trim")
    public static let upper: Self = .init("upper")
    public static let stringAgg: Self = .init("string_agg")
    @available(*, deprecated, renamed: "stringAgg")
    public static var string_agg: Self { .stringAgg }
    public static let regExpReplace: Self = .init("regexp_replace")
    @available(*, deprecated, renamed: "regExpReplace")
    public static var regexp_replace: Self { .regExpReplace }
} 

extension Fn {
    /// String and non-string concatenation
    /// e.g. `'Post' || 'greSQL'` will return `PostgreSQL`
    /// so in Swift you can write it like `"Post" || "greSQL"`
    /// or using KeyPath like \User.firstName || " " || \User.lastName
    /// and KeyPath alias like u+\.firstName || " " || u+\.lastName
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/concat2.php)
    public static func concatStrings(lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = lhs.parts
        parts.append(o: .space)
        parts.append(o: .custom("||"))
        parts.append(o: .space)
        parts.append(contentsOf: rhs.parts)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
    }
    
    /// Number of bits in string
    /// e.g. `bit_length('jose')` will return 32
    /// [Learn more →]()
    public static func bitLength(_ string: SwifQLable) -> SwifQLable {
        build(.bitLength, body: string.parts)
    }

    @available(*, deprecated, renamed: "bitLength(_:)")
    public static func bit_length(_ string: SwifQLable) -> SwifQLable {
        bitLength(string)
    }
    
    /// Removes all specified characters from both the beginning and the end of a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/btrim.php)
    public static func bTrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: characters)
        return build(.bTrim, body: parts)
    }

    @available(*, deprecated, renamed: "bTrim(_:_:)")
    public static func btrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        bTrim(string, characters)
    }
    
    /// Returns the length of the specified string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/char_length.php)
    public static func charLength(_ string: SwifQLable) -> SwifQLable {
        build(.charLength, body: string.parts)
    }

    @available(*, deprecated, renamed: "charLength(_:)")
    public static func char_length(_ string: SwifQLable) -> SwifQLable {
        charLength(string)
    }
    
    /// Returns the length of the specified string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/character_length.php)
    public static func characterLength(_ string: SwifQLable) -> SwifQLable {
        build(.characterLength, body: string.parts)
    }

    @available(*, deprecated, renamed: "characterLength(_:)")
    public static func character_length(_ string: SwifQLable) -> SwifQLable {
        characterLength(string)
    }
    
    /// Converts the first letter of each word to uppercase and all other letters are converted to lowercase
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/initcap.php)
    public static func initCap(_ string: SwifQLable) -> SwifQLable {
        build(.initCap, body: string.parts)
    }

    @available(*, deprecated, renamed: "initCap(_:)")
    public static func initcap(_ string: SwifQLable) -> SwifQLable {
        initCap(string)
    }
    
    /// Concatenate all arguments. NULL arguments are ignored.
    ///
    /// # Example
    /// ```swift
    /// Fn.concat("Hello ", \User.name)
    /// ```
    /// # Result
    /// ```
    /// concat('Hello ', "User"."name")
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/functions-string.html)
    public static func concat(_ values: SwifQLable...) -> SwifQLable {
        concat(values)
    }
    
    /// Concatenate all arguments. NULL arguments are ignored.
    ///
    /// # Example
    /// ```swift
    /// Fn.concat("Hello ", \User.name)
    /// ```
    /// # Result
    /// ```
    /// concat('Hello ', "User"."name")
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/functions-string.html)
    public static func concat(_ values: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = []
        values.enumerated().forEach { offset, value in
            parts.append(contentsOf: value.parts)
            if offset < values.count - 1 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
        }
        return build(.concat, body: parts)
    }
    
    /// Concatenate all arguments. NULL arguments are ignored.
    ///
    /// # Example
    /// ```swift
    /// Fn.concatWS(", ", "Hello", \User.name)
    /// ```
    /// # Result
    /// ```
    /// concat_ws(', ', 'Hello', "User"."name")
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/functions-string.html)
    public static func concatWS(_ values: SwifQLable...) -> SwifQLable {
        concatWS(values)
    }

    @available(*, deprecated, renamed: "concatWS(_:)")
    public static func concat_ws(_ values: SwifQLable...) -> SwifQLable {
        concatWS(values)
    }
    
    /// Concatenate all arguments. NULL arguments are ignored.
    ///
    /// # Example
    /// ```swift
    /// Fn.concatWS(", ", "Hello", \User.name)
    /// ```
    /// # Result
    /// ```
    /// concat_ws(', ', 'Hello', "User"."name")
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/functions-string.html)
    public static func concatWS(_ values: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = []
        values.enumerated().forEach { offset, value in
            parts.append(contentsOf: value.parts)
            if offset < values.count - 1 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
        }
        return build(.concatWS, body: parts)
    }

    @available(*, deprecated, renamed: "concatWS(_:)")
    public static func concat_ws(_ values: [SwifQLable]) -> SwifQLable {
        concatWS(values)
    }
    
    /// Returns the length of the requested array dimension
    public static func arrayLength(_ anyArray: SwifQLable, _ dimension: Int = 1) -> SwifQLable {
        var parts: [SwifQLPart] = anyArray.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: dimension)
        return build(.arrayLength, body: parts)
    }

    @available(*, deprecated, renamed: "arrayLength(_:_:)")
    public static func array_length(_ anyArray: SwifQLable, _ dimension: Int = 1) -> SwifQLable {
        arrayLength(anyArray, dimension)
    }
    
    /// Returns the length of the specified string, expressed as the number of characters.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/length.php)
    public static func length(_ string: SwifQLable) -> SwifQLable {
        build(.length, body: string.parts)
    }
    
    /// Converts all characters in the specified string to lowercase
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/lower.php)
    public static func lower(_ string: SwifQLable) -> SwifQLable {
        build(.lower, body: string.parts)
    }
    
    /// Returns a string that is left-padded with a specified string to a certain length
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/lpad.php)
    public static func lPad(_ string: SwifQLable, _ length: Int, _ padString: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: length)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: padString.parts)
        return build(.lPad, body: parts)
    }

    @available(*, deprecated, renamed: "lPad(_:_:_:)")
    public static func lpad(_ string: SwifQLable, _ length: Int, _ padString: SwifQLable) -> SwifQLable {
        lPad(string, length, padString)
    }
    
    /// Removes all specified characters from the left-hand side of a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/ltrim.php)
    public static func lTrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: characters)
        return build(.lTrim, body: parts)
    }

    @available(*, deprecated, renamed: "lTrim(_:_:)")
    public static func ltrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        lTrim(string, characters)
    }
    
    /// Returns the location of a substring in a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/position.php)
    public static func position(_ substring: SwifQLable, in string: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = substring.parts
        parts.append(o: .space)
        parts.append(o: .in)
        parts.append(o: .space)
        parts.append(contentsOf: string.parts)
        return build(.position, body: parts)
    }
    
    /// Repeats a string a specified number of times
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/repeat.php)
    public static func `repeat`(_ string: SwifQLable, _ number: Int) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: number)
        return build(.repeat, body: parts)
    }
    
    /// Replaces all occurrences of a specified string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/replace.php)
    public static func replace(_ string: SwifQLable, _ fromSubstring: SwifQLable, _ toSubstring: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: fromSubstring.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: toSubstring.parts)
        return build(.replace, body: parts)
    }
    
    /// Returns a string that is right-padded with a specified string to a certain length
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/rpad.php)
    public static func rPad(_ string: SwifQLable, _ length: Int, _ padString: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: length)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: padString.parts)
        return build(.rPad, body: parts)
    }

    @available(*, deprecated, renamed: "rPad(_:_:_:)")
    public static func rpad(_ string: SwifQLable, _ length: Int, _ padString: SwifQLable) -> SwifQLable {
        rPad(string, length, padString)
    }
    
    /// Removes all specified characters from the right-hand side of a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/rtrim.php)
    public static func rTrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(safe: characters)
        return build(.rTrim, body: parts)
    }

    @available(*, deprecated, renamed: "rTrim(_:_:)")
    public static func rtrim(_ string: SwifQLable, _ characters: String) -> SwifQLable {
        rTrim(string, characters)
    }
    
    /// Returns the location of a substring in a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/strpos.php)
    public static func strPos(_ string: SwifQLable, _ substring: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: substring.parts)
        return build(.strPos, body: parts)
    }

    @available(*, deprecated, renamed: "strPos(_:_:)")
    public static func strpos(_ string: SwifQLable, _ substring: SwifQLable) -> SwifQLable {
        strPos(string, substring)
    }
    
    /// Allows you to extract a substring from a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/substring.php)
    public static func substring(_ string: SwifQLable, from startPosition: Int) -> SwifQLable {
        _substring(string, from: startPosition)
    }
    /// Allows you to extract a substring from a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/substring.php)
    public static func substring(_ string: SwifQLable, for length: Int) -> SwifQLable {
        _substring(string, for: length)
    }
    /// Allows you to extract a substring from a string
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/substring.php)
    public static func substring(_ string: SwifQLable, from startPosition: Int, for length: Int) -> SwifQLable {
        _substring(string, from: startPosition, for: length)
    }
    private static func _substring(_ string: SwifQLable, from startPosition: Int? = nil, for length: Int? = nil) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        if let startPosition = startPosition {
            parts.append(o: .space)
            parts.append(o: .from)
            parts.append(o: .space)
            parts.append(safe: startPosition)
        }
        if let length = length {
            parts.append(o: .space)
            parts.append(o: .for)
            parts.append(o: .space)
            parts.append(safe: length)
        }
        return build(.substring, body: parts)
    }
    
    /// Replaces a sequence of characters in a string with another set of characters. However, it replaces a single character at a time.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/translate.php)
    public static func translate(_ string: SwifQLable, _ stringToReplace: SwifQLable, _ replacementString: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = string.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: stringToReplace.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: replacementString.parts)
        return build(.translate, body: parts)
    }
    
    /// Removes all specified characters either from the beginning or the end of a string.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/trim.php)
    public static func trim(_ string: SwifQLable) -> SwifQLable {
        build(.trim, body: string.parts)
    }
    
    /// Removes all specified characters either from the beginning or the end of a string.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/trim.php)
    public static func trim(leading trimCharacter: SwifQLable? = nil, from string: SwifQLable) -> SwifQLable {
        _trim("leading", trimCharacter, from: string)
    }
    /// Removes all specified characters either from the beginning or the end of a string.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/trim.php)
    public static func trim(trailing trimCharacter: SwifQLable? = nil, from string: SwifQLable) -> SwifQLable {
        _trim("trailing", trimCharacter, from: string)
    }
    /// Removes all specified characters either from the beginning or the end of a string.
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/trim.php)
    public static func trim(both trimCharacter: SwifQLable? = nil, from string: SwifQLable) -> SwifQLable {
        _trim("both", trimCharacter, from: string)
    }
    
    /// Private `trim` builder method
    private static func _trim(_ type: String, _ trimCharacter: SwifQLable? = nil, from string: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = []
        parts.append(o: .custom(type))
        if let trimCharacter = trimCharacter {
            parts.append(o: .space)
            parts.append(contentsOf: trimCharacter.parts)
        }
        parts.append(o: .space)
        parts.append(o: .from)
        parts.append(o: .space)
        parts.append(contentsOf: string.parts)
        return build(.trim, body: string.parts)
    }
    
    /// Converts all characters in the specified string to uppercase
    /// [Learn more →](https://www.techonthenet.com/postgresql/functions/upper.php)
    public static func upper(_ string: SwifQLable) -> SwifQLable {
        build(.upper, body: string.parts)
    }

    /// Concatenates non-null input values into a string, separated by delimiter
    /// [Learn more →](https://www.postgresql.org/docs/11/functions-aggregate.html)
    public static func stringAgg(_ string: SwifQLable, _ separator: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = []
        parts.append(contentsOf: string.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: separator.parts)
        return build(.stringAgg, body: parts)
    }

    @available(*, deprecated, renamed: "stringAgg(_:_:)")
    public static func string_agg(_ string: SwifQLable, _ separator: SwifQLable) -> SwifQLable {
        stringAgg(string, separator)
    }
    
    /// Replaces a sequence of characters in a string with another set of characters using regular expression pattern matching
    /// [Learn more →](https://www.techonthenet.com/oracle/functions/regexp_replace.php)
    public static func regExpReplace(_ string: SwifQLable, _ fromRegexp: SwifQLable, _ toSubstring: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = []
        parts.append(contentsOf: string.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: fromRegexp.parts)
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: toSubstring.parts)
        return build(.regExpReplace, body: parts)
    }

    @available(*, deprecated, renamed: "regExpReplace(_:_:_:)")
    public static func regexp_replace(_ string: SwifQLable, _ fromRegexp: SwifQLable, _ toSubstring: SwifQLable) -> SwifQLable {
        regExpReplace(string, fromRegexp, toSubstring)
    }
}
