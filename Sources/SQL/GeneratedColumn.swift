public enum GeneratedColumnStorage {
    case virtual
    case stored
}

public struct GeneratedColumn: SQLable {
    private let name: String
    private let type: Type?
    private let expression: SQLable
    private let storage: GeneratedColumnStorage?

    public init(
        _ name: String,
        as expression: SQLable,
        storage: GeneratedColumnStorage? = nil
    ) {
        self.name = name
        self.type = nil
        self.expression = expression
        self.storage = storage
    }

    public init(
        _ name: String,
        _ type: Type,
        generatedAlwaysAs expression: SQLable,
        storage: GeneratedColumnStorage? = nil
    ) {
        self.name = name
        self.type = type
        self.expression = expression
        self.storage = storage
    }

    public var parts: [SQLPart] {
        var parts: [SQLPart] = [SQLPartColumn(name)]
        if let type {
            parts.append(o: .space)
            parts.append(SQLPartType(type))
            parts.append(o: .space, .custom("GENERATED"), .space, .custom("ALWAYS"))
        }
        parts.append(o: .space, .as, .space, .openBracket)
        parts.append(contentsOf: expression.parts)
        parts.append(o: .closeBracket)
        if let storage {
            switch storage {
            case .virtual:
                parts.append(o: .space, .custom("VIRTUAL"))
            case .stored:
                parts.append(o: .space, .custom("STORED"))
            }
        }
        return parts
    }
}
