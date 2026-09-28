//
//  SwifQLable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public protocol SwifQLable: CustomStringConvertible, RowField {
    var parts: [SwifQLPart] { get }
}

extension SwifQLable {
    public var rowFieldValue: RowFieldValue { .expression(parts) }

    public var description: String { prepare(.psql).plain }
}

public struct SwifQLableParts: SwifQLable {
    public var parts: [SwifQLPart]
    public init (parts: SwifQLPart...) {
        self.init(parts: parts)
    }
    public init (parts: [SwifQLPart]) {
        guard let frame = parts.first as? SwifQLStructuralFramePart else {
            self.parts = parts
            return
        }

        var appended = Array(parts.dropFirst())
        if let first = appended.first as? SwifQLPartOperator, first._value == " " {
            let rootAlreadyEndsInSpace: Bool
            if let last = frame.children.last as? SwifQLPartOperator {
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

public protocol SwifQLPart {}

public protocol SwifQLKeyPathable: SwifQLPart {
    var schema: String? { get }
    var table: String? { get }
    var paths: [String] { get }
}

extension SwifQLable {
    /// Good choice only for super short and universal queries like `BEGIN;`, `ROLLBACK;`, `COMMIT;`
    public func prepare() -> SwifQLPrepared {
        prepare(.any)
    }

    public func prepare(_ dialect: SQLDialect) -> SwifQLPrepared {
        SwifQLPreparationRenderer(dialect: dialect, mode: .legacy)
            .prepare(parts)
            .prepared
    }

    public func prepareObservingUnsafeValues(
        _ dialect: SQLDialect
    ) -> SwifQLObservedPrepared {
        let result = SwifQLPreparationRenderer(
            dialect: dialect,
            mode: .observeUnsafeValues
        ).prepare(parts)
        return .init(
            prepared: result.prepared,
            unsafeValueTrace: result.unsafeValueTrace
        )
    }
}
