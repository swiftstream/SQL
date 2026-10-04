import Foundation

extension SQLable {
    public var or: SQLable {
        appendingAtomicKeyword(.or)
    }

    public var replace: SQLable {
        appendingAtomicKeyword(.replace)
    }

    public var view: SQLable {
        appendingAtomicKeyword(.custom("VIEW"))
    }

    public var sequence: SQLable {
        appendingAtomicKeyword(.custom("SEQUENCE"))
    }

    public var macro: SQLable {
        appendingAtomicKeyword(.custom("MACRO"))
    }

    public var index: SQLable {
        appendingAtomicKeyword(.custom("INDEX"))
    }

    public var temp: SQLable {
        appendingAtomicKeyword(.custom("TEMP"))
    }

    public var temporary: SQLable {
        appendingAtomicKeyword(.custom("TEMPORARY"))
    }

    public var ignore: SQLable {
        appendingAtomicKeyword(.custom("IGNORE"))
    }

    public var name: SQLable {
        appendingAtomicKeyword(.custom("NAME"))
    }

    public var when: SQLable {
        appendingAtomicKeyword(.when)
    }

    public var matched: SQLable {
        appendingAtomicKeyword(.custom("MATCHED"))
    }

    public var source: SQLable {
        appendingAtomicKeyword(.custom("SOURCE"))
    }

    public var target: SQLable {
        appendingAtomicKeyword(.custom("TARGET"))
    }

    public var cycle: SQLable {
        appendingAtomicKeyword(.custom("CYCLE"))
    }

    public var minValue: SQLable {
        appendingAtomicKeyword(.custom("MINVALUE"))
    }

    public var maxValue: SQLable {
        appendingAtomicKeyword(.custom("MAXVALUE"))
    }

    public var data: SQLable {
        appendingAtomicKeyword(.data)
    }

    private func appendingAtomicKeyword(_ keyword: SQLPartOperator) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: keyword)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
