import Foundation

public func From(
    @FromBuilder _ content: () -> FromBuilder.Result
) -> FromBuilder.Result {
    content()
}
