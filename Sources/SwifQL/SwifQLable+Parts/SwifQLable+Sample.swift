import Foundation

/// An open, value-semantic identity for a sampling method.
public struct SampleMethod: Hashable, Sendable, SQLable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public init(_ name: String) {
        self.init(namespace: "swifql", name: name)
    }

    /// Source-compatible raw-value construction, now open rather than failable
    /// for a closed enum's known cases.
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String { name }

    public static let system = Self(namespace: "swifql", name: "system")
    public static let bernoulli = Self(namespace: "swifql", name: "bernoulli")
    public static let reservoir = Self(namespace: "swifql", name: "reservoir")

    public var parts: [SQLPart] {
        [SQLPartOperator(name)]
    }
}

/// An open semantic role/unit for one ordered sampling argument.
public struct SampleArgumentRole: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let percentage = Self(namespace: "swifql", name: "percentage")
    public static let rows = Self(namespace: "swifql", name: "rows")
}

/// A value-semantic ordered sampling argument whose expression remains intact
/// until a dialect chooses its exact grammar and bindability policy.
public struct SampleArgument: SQLable {
    public let value: SQLable
    public let role: SampleArgumentRole?

    public init(_ value: SQLable, role: SampleArgumentRole? = nil) {
        self.value = value
        self.role = role
    }

    public init(percentage value: SQLable) {
        self.init(value, role: .percentage)
    }

    public init(rows value: SQLable) {
        self.init(value, role: .rows)
    }

    public var parts: [SQLPart] {
        value.parts
    }
}

/// A size convenience retained for existing sampling call sites. Its semantic
/// value remains an ordinary `SQLable`; the selected dialect owns whether
/// the value is bound or represented as a parser constant.
public struct SampleSize: SQLable {
    public enum Kind: Equatable, Sendable {
        case percentage
        case rows
    }

    public let kind: Kind
    public let value: SQLable

    public init(_ value: SQLable, kind: Kind) {
        self.kind = kind
        self.value = value
    }

    public init(percentage value: SQLable) {
        self.init(value, kind: .percentage)
    }

    public init(rows value: SQLable) {
        self.init(value, kind: .rows)
    }

    public var argument: SampleArgument {
        SampleArgument(value, role: kind == .percentage ? .percentage : .rows)
    }

    public var parts: [SQLPart] {
        value.parts
    }
}

/// The optional seed role in USING SAMPLE remains separate from method
/// arguments while retaining its original expression/value semantics.
public struct SampleSeed: SQLable {
    public let value: SQLable

    public init(_ value: SQLable) {
        self.value = value
    }

    public var parts: [SQLPart] { value.parts }
}

/// The optional repeatability role in TABLESAMPLE remains separate from method
/// arguments while retaining its original expression/value semantics.
public struct SampleRepeatability: SQLable {
    public let value: SQLable

    public init(_ value: SQLable) {
        self.value = value
    }

    public var parts: [SQLPart] { value.parts }
}

/// The two currently modeled sampling clause identities remain distinct while
/// retaining value semantics for future dialect-specific policies.
public struct SampleConstruct: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let usingSample = Self(namespace: "swifql", name: "usingSample")
    public static let tableSample = Self(namespace: "swifql", name: "tableSample")
}

/// A structured sampling value passed to the single dialect rendering hook.
public struct SQLPartSampling: SQLPart {
    public let construct: SampleConstruct
    public let method: SampleMethod?
    public let arguments: [SampleArgument]
    public let seed: SampleSeed?
    public let repeatability: SampleRepeatability?

    public init(
        construct: SampleConstruct,
        method: SampleMethod? = nil,
        arguments: [SampleArgument] = [],
        seed: SampleSeed? = nil,
        repeatability: SampleRepeatability? = nil
    ) {
        self.construct = construct
        self.method = method
        self.arguments = arguments
        self.seed = seed
        self.repeatability = repeatability
    }

    internal func renderedParts(
        argumentParts: [[SQLPart]],
        seedParts: [SQLPart]?,
        repeatabilityParts: [SQLPart]?
    ) -> [SQLPart] {
        var parts: [SQLPart] = []
        let firstRole = arguments.first?.role

        if construct == .usingSample {
            parts.append(o: .using, .space, .custom("SAMPLE"), .space)
            if let first = argumentParts.first {
                parts.append(contentsOf: first)
                if firstRole == .percentage {
                    parts.append(o: .custom("%"))
                }
            }
            for argument in argumentParts.dropFirst() {
                parts.append(o: .comma, .space)
                parts.append(contentsOf: argument)
            }
            if let method {
                parts.append(o: .space, .openBracket)
                parts.append(contentsOf: method.parts)
                if let seedParts {
                    parts.append(o: .comma, .space)
                    parts.append(contentsOf: seedParts)
                }
                parts.append(o: .closeBracket)
            }
            return parts
        }

        if construct == .tableSample {
            parts.append(o: .custom("TABLESAMPLE"), .space)
            if let method {
                parts.append(contentsOf: method.parts)
            }
            parts.append(o: .openBracket)
            if let first = argumentParts.first {
                parts.append(contentsOf: first)
                if firstRole == .percentage || firstRole == .rows {
                    parts.append(o: .space)
                    parts.append(o: .custom(firstRole == .percentage ? "PERCENT" : "ROWS"))
                }
            }
            for argument in argumentParts.dropFirst() {
                parts.append(o: .comma, .space)
                parts.append(contentsOf: argument)
            }
            parts.append(o: .closeBracket)
            if let repeatabilityParts {
                parts.append(o: .space, .custom("REPEATABLE"), .space, .openBracket)
                parts.append(contentsOf: repeatabilityParts)
                parts.append(o: .closeBracket)
            }
            return parts
        }

        return [
            SQLPartOperator(
                "<sampling_construct_requires_explicit_\(construct.name)_branch>"
            )
        ]
    }
}

/// The value-semantic options inside a distinct USING SAMPLE clause.
public struct Sample: SQLable {
    public let arguments: [SampleArgument]
    public let method: SampleMethod?
    public let seed: SampleSeed?

    public init(
        arguments: [SampleArgument],
        method: SampleMethod? = nil,
        seed: SQLable? = nil
    ) {
        self.arguments = arguments
        self.method = method
        self.seed = seed.map(SampleSeed.init)
    }

    public init(_ size: SampleSize, method: SampleMethod? = nil) {
        self.init(arguments: [size.argument], method: method)
    }

    public init(_ size: SampleSize, method: SampleMethod, seed: Int) {
        self.init(arguments: [size.argument], method: method, seed: seed)
    }

    public init(_ size: SampleSize, method: SampleMethod, seed: SQLable) {
        self.init(arguments: [size.argument], method: method, seed: seed)
    }

    public var parts: [SQLPart] {
        [SQLPartSampling(
            construct: .usingSample,
            method: method,
            arguments: arguments,
            seed: seed
        )]
    }
}

/// The value-semantic options inside a distinct TABLESAMPLE table-reference
/// suffix.
public struct TableSample: SQLable {
    public let arguments: [SampleArgument]
    public let method: SampleMethod?
    public let repeatable: SampleRepeatability?
    private let sourceSnapshot: [SQLPart]?

    public init(
        arguments: [SampleArgument],
        method: SampleMethod? = nil,
        repeatable: SQLable? = nil
    ) {
        self.arguments = arguments
        self.method = method
        self.repeatable = repeatable.map(SampleRepeatability.init)
        self.sourceSnapshot = nil
    }

    init(source: SQLable, options: TableSampleBuilder.Options) {
        self.arguments = options.arguments
        self.method = options.method
        self.repeatable = options.repeatable.map(SampleRepeatability.init)
        self.sourceSnapshot = source.parts
    }

    public init(_ size: SampleSize) {
        self.init(arguments: [size.argument])
    }

    public init(_ size: SampleSize, method: SampleMethod) {
        self.init(arguments: [size.argument], method: method)
    }

    public init(_ size: SampleSize, method: SampleMethod, repeatable: Int) {
        self.init(arguments: [size.argument], method: method, repeatable: repeatable)
    }

    public init(_ size: SampleSize, method: SampleMethod, repeatable: SQLable) {
        self.init(arguments: [size.argument], method: method, repeatable: repeatable)
    }

    public var parts: [SQLPart] {
        let samplingPart = SQLPartSampling(
            construct: .tableSample,
            method: method,
            arguments: arguments,
            repeatability: repeatable
        )

        guard var sourceParts = sourceSnapshot else {
            return [samplingPart]
        }

        sourceParts.appendSpaceIfNeeded()
        sourceParts.append(samplingPart)
        return sourceParts
    }
}

extension SQLable {
    /// Appends a SELECT-level USING SAMPLE clause.
    public func usingSample(_ sample: Sample) -> SQLable {
        return structurallyAppending(SQLableParts(parts:
            [SQLPartOperator.space] + sample.parts
        ))
    }

    /// Appends a TABLESAMPLE suffix to a table reference.
    public func tableSample(_ sample: TableSample) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(contentsOf: sample.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
