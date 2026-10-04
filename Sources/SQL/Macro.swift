//
//  Macro.swift
//  SwifQL
//

public struct MacroParameter: SQLable {
    public let name: String
    public let type: Type?

    public init(_ name: String, _ type: Type? = nil) {
        self.name = name
        self.type = type
    }

    public var parts: [SQLPart] {
        [SQLPartIdentifier(name)]
    }

    fileprivate var declarationParts: [SQLPart] {
        var parts: [SQLPart] = [SQLPartIdentifier(name)]
        if let type {
            parts.append(o: .space)
            parts.append(SQLPartType(type))
        }
        return parts
    }
}

extension SQLable {
    public func macroParameters(_ parameters: MacroParameter...) -> SQLable {
        macroParameters(parameters)
    }

    public func macroParameters(_ parameters: [MacroParameter]) -> SQLable {
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

extension Fn {
    public static func call(_ name: Path.Identifier, _ arguments: SQLable...) -> SQLable {
        call(name, arguments)
    }

    public static func call(_ name: Path.Identifier, _ arguments: [SQLable]) -> SQLable {
        var parts = name.parts
        parts.append(o: .openBracket)
        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: argument.parts)
        }
        parts.append(o: .closeBracket)
        return SQLableParts(parts: parts)
    }
}
