import Foundation

//MARK: QUALIFY

extension SwifQLable {
    /// Appends a QUALIFY predicate to the current SQL composition.
    public func qualify(_ predicate: SwifQLable) -> SwifQLable {
        let parts: [SwifQLPart] = [SwifQLPartOperator.space, .custom("QUALIFY"), .space] + predicate.parts
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
