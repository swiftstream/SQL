import Foundation

extension SwifQLable {
    public var or: SwifQLable {
        appendingAtomicKeyword(.or)
    }

    public var replace: SwifQLable {
        appendingAtomicKeyword(.replace)
    }

    public var view: SwifQLable {
        appendingAtomicKeyword(.custom("VIEW"))
    }

    public var sequence: SwifQLable {
        appendingAtomicKeyword(.custom("SEQUENCE"))
    }

    public var macro: SwifQLable {
        appendingAtomicKeyword(.custom("MACRO"))
    }

    public var index: SwifQLable {
        appendingAtomicKeyword(.custom("INDEX"))
    }

    public var temp: SwifQLable {
        appendingAtomicKeyword(.custom("TEMP"))
    }

    public var temporary: SwifQLable {
        appendingAtomicKeyword(.custom("TEMPORARY"))
    }

    public var ignore: SwifQLable {
        appendingAtomicKeyword(.custom("IGNORE"))
    }

    public var name: SwifQLable {
        appendingAtomicKeyword(.custom("NAME"))
    }

    public var when: SwifQLable {
        appendingAtomicKeyword(.when)
    }

    public var matched: SwifQLable {
        appendingAtomicKeyword(.custom("MATCHED"))
    }

    public var source: SwifQLable {
        appendingAtomicKeyword(.custom("SOURCE"))
    }

    public var target: SwifQLable {
        appendingAtomicKeyword(.custom("TARGET"))
    }

    public var cycle: SwifQLable {
        appendingAtomicKeyword(.custom("CYCLE"))
    }

    public var minValue: SwifQLable {
        appendingAtomicKeyword(.custom("MINVALUE"))
    }

    public var maxValue: SwifQLable {
        appendingAtomicKeyword(.custom("MAXVALUE"))
    }

    public var data: SwifQLable {
        appendingAtomicKeyword(.data)
    }

    private func appendingAtomicKeyword(_ keyword: SwifQLPartOperator) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: keyword)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
