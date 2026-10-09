import Foundation

/// Exact grouped binary operator escape: `lhs <op> rhs` lowers as one
/// unconditional parentheses group `( + lhs + space + op + space + rhs + )`.
///
/// The token spelling cannot become a Swift operator overload; composition
/// stays ordinary part traversal with no precedence table, renderer branch,
/// or token-history scan. Operands are snapshotted exactly once.
extension SQLable {
    public func op(_ op: SQLPartOperator, _ rhs: SQLable) -> SQLable {
        let lhsParts = self.parts
        let rhsParts = rhs.parts
        var parts: [SQLPart] = []
        parts.append(o: .openBracket)
        parts.append(contentsOf: lhsParts)
        parts.append(o: .space)
        parts.append(op)
        parts.append(o: .space)
        parts.append(contentsOf: rhsParts)
        parts.append(o: .closeBracket)
        return SQLableParts(rawParts: parts)
    }
}
