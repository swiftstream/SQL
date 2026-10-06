import Foundation

public func From(
    @FromBuilder _ content: () -> FromBuilder.Result
) -> FromBuilder.Result {
    content()
}

public func From(
    _ first: any SQLable,
    _ rest: any SQLable...
) -> FromBuilder.Result {
    FromBuilder.conciseResult(from: [first] + rest)
}
