import Foundation

/// A request inside a declarative TABLESAMPLE options block.
public struct TableSampleRequest {
    enum Kind {
        case method(SampleMethod, SQLable)
        case repeatable(SQLable)
    }

    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }
}

/// Completed options for the source-owning `TableSample` initializer.
@resultBuilder
public enum TableSampleBuilder {
    public struct Options {
        let arguments: [SampleArgument]
        let method: SampleMethod?
        let repeatable: SQLable?

        init(
            arguments: [SampleArgument] = [],
            method: SampleMethod? = nil,
            repeatable: SQLable? = nil
        ) {
            self.arguments = arguments
            self.method = method
            self.repeatable = repeatable
        }
    }

    public static func buildExpression(_ request: TableSampleRequest) -> [TableSampleRequest] {
        [request]
    }

    public static func buildBlock(_ components: [TableSampleRequest]...) -> Options {
        var arguments: [SampleArgument] = []
        var method: SampleMethod?
        var repeatable: SQLable?

        for request in components.flatMap({ $0 }) {
            switch request.kind {
            case let .method(value, argument):
                method = value
                arguments.append(SampleArgument(percentage: argument))
            case let .repeatable(value):
                repeatable = value
            }
        }

        return Options(arguments: arguments, method: method, repeatable: repeatable)
    }
}

/// Requests SYSTEM sampling with a percentage-role argument.
public func System(_ percentage: SQLable) -> TableSampleRequest {
    TableSampleRequest(.method(.system, percentage))
}

/// Requests BERNOULLI sampling with a percentage-role argument.
public func Bernoulli(_ percentage: SQLable) -> TableSampleRequest {
    TableSampleRequest(.method(.bernoulli, percentage))
}

/// Adds the TABLESAMPLE REPEATABLE seed.
public func Repeatable(_ seed: SQLable) -> TableSampleRequest {
    TableSampleRequest(.repeatable(seed))
}

extension TableSample {
    /// Creates a source-owning TABLESAMPLE value using existing sampling semantics.
    public init(
        _ source: SQLable,
        @TableSampleBuilder _ options: () -> TableSampleBuilder.Options
    ) {
        self.init(source: source, options: options())
    }
}
