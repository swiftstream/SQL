//
//  ReferentialAction.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

public struct ReferentialAction: SQLable {
    public var parts: [SQLPart] { query.parts }
    var query: SQLable
    
    public init (_ expression: SQLable) {
        query = expression
    }
    
    /// Produce an error indicating that the deletion or update
    /// would create a foreign key constraint violation.
    /// If the constraint is deferred, this error will be produced at constraint
    /// check time if there still exist any referencing rows. This is the default action.
    public static var noAction: ReferentialAction { .init(SQL.no.action) }

    /// Produce an error indicating that the deletion or update
    /// would create a foreign key constraint violation.
    /// This is the same as NO ACTION except that the check is not deferrable.
    public static var restrict: ReferentialAction { .init(SQL.restrict) }

    /// Delete any rows referencing the deleted row,
    /// or update the values of the referencing column(s)
    /// to the new values of the referenced columns, respectively.
    public static var cascade: ReferentialAction { .init(SQL.cascade) }

    /// Set the referencing column(s) to null.
    public static var setNull: ReferentialAction { .init(SQL.set.null) }

    /// Set the referencing column(s) to their default values.
    /// (There must be a row in the referenced table matching the default values,
    /// if they are not null, or the operation will fail.)
    public static var setDefault: ReferentialAction { .init(SQL.set.default) }
}
