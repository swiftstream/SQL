//
//  Sequence.swift
//  SwifQL
//

extension SQLable {
    public func start(_ value: Int64) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("START"), .space)
        parts.append(safe: value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    public func start(with value: Int64) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("START"), .space, .with, .space)
        parts.append(safe: value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    public func increment(by value: Int64) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("INCREMENT"), .space, .by, .space)
        parts.append(safe: value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    public func minValue(_ value: Int64) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("MINVALUE"), .space)
        parts.append(safe: value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    public func maxValue(_ value: Int64) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("MAXVALUE"), .space)
        parts.append(safe: value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
