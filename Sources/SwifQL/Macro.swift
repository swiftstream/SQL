//
//  Macro.swift
//  SwifQL
//

public struct MacroParameter: SwifQLable {
    public let name: String
    public let type: Type?

    public init(_ name: String, _ type: Type? = nil) {
        self.name = name
        self.type = type
    }

    public var parts: [SwifQLPart] {
        [SwifQLPartIdentifier(name)]
    }

    fileprivate var declarationParts: [SwifQLPart] {
        var parts: [SwifQLPart] = [SwifQLPartIdentifier(name)]
        if let type {
            parts.append(o: .space)
            parts.append(SwifQLPartType(type))
        }
        return parts
    }
}

extension SwifQLable {
    public func macroParameters(_ parameters: MacroParameter...) -> SwifQLable {
        macroParameters(parameters)
    }

    public func macroParameters(_ parameters: [MacroParameter]) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        for (index, parameter) in parameters.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: parameter.declarationParts)
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

extension Fn {
    public static func call(_ name: Path.Identifier, _ arguments: SwifQLable...) -> SwifQLable {
        call(name, arguments)
    }

    public static func call(_ name: Path.Identifier, _ arguments: [SwifQLable]) -> SwifQLable {
        var parts = name.parts
        parts.append(o: .openBracket)
        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: argument.parts)
        }
        parts.append(o: .closeBracket)
        return SwifQLableParts(parts: parts)
    }
}
