import Foundation

//MARK: QUALIFY

extension SQLable {
    /// Appends a QUALIFY predicate to the current SQL composition.
    public func qualify(_ predicate: SQLable) -> SQLable {
        let parts: [SQLPart] = [SQLPartOperator.space, .custom("QUALIFY"), .space] + predicate.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
