//
//  SQLable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public protocol SQLable: CustomStringConvertible, RowField {
    var parts: [SQLPart] { get }
}

extension SQLable {
    public var rowFieldValue: RowFieldValue { .expression(parts) }

    public var description: String { prepare(.psql).plain }
}

public struct SQLableParts: SQLable {
    public var parts: [SQLPart]
    public init (parts: SQLPart...) {
        self.init(parts: parts)
    }
    public init (parts: [SQLPart]) {
        guard let frame = parts.first as? SQLStructuralFramePart else {
            self.parts = parts
            return
        }

        var appended = Array(parts.dropFirst())
        if let first = appended.first as? SQLPartOperator, first._value == " " {
            let rootAlreadyEndsInSpace: Bool
            if let last = frame.children.last as? SQLPartOperator {
                rootAlreadyEndsInSpace = last._value == " "
            } else {
                rootAlreadyEndsInSpace = false
            }
            if frame.children.isEmpty || rootAlreadyEndsInSpace {
                appended.removeFirst()
            }
        }

        self.parts = [frame.appending(appended)]
    }
}

public protocol SQLPart {}

public protocol SQLKeyPathable: SQLPart {
    var schema: String? { get }
    var table: String? { get }
    var paths: [String] { get }
}

extension SQLable {
    /// Good choice only for super short and universal queries like `BEGIN;`, `ROLLBACK;`, `COMMIT;`
    public func prepare() -> SQLPrepared {
        prepare(.any)
    }

    public func prepare(_ dialect: SQLDialect) -> SQLPrepared {
        SQLPreparationRenderer(dialect: dialect, mode: .legacy)
            .prepare(parts)
            .prepared
    }

    public func prepareObservingUnsafeValues(
        _ dialect: SQLDialect
    ) -> SQLObservedPrepared {
        let result = SQLPreparationRenderer(
            dialect: dialect,
            mode: .observeUnsafeValues
        ).prepare(parts)
        return .init(
            prepared: result.prepared,
            unsafeValueTrace: result.unsafeValueTrace
        )
    }
}