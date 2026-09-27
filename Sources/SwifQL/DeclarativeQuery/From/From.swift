import Foundation

@_disfavoredOverload
public func From(
    @FromBuilder _ content: () -> FromBuilder.Result
) -> FromBuilder.Result {
    content()
}

public func From(
    @GuaranteedFromBuilder _ content: () -> FromBuilder.GuaranteedResult,
    _ typedCarrierBridge: Void = ()
) -> FromBuilder.GuaranteedResult {
    content()
}
