import Foundation

/// Builds a comma-separated list of completed SQL FROM items.
public func From(
    @FromBuilder _ content: () -> FromBuilder.Result
) -> FromBuilder.Result {
    content()
}
