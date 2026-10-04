//
//  Functions+Time.swift
//  SwifQL
//

extension Fn {
    /// Emits the exact SQL `current_time` keyword.
    public static var currentTime: SQLable {
        SQLableParts(parts: Name.currentTime.part)
    }

    /// Emits the exact SQL `current_timestamp` keyword.
    public static var currentTimestamp: SQLable {
        SQLableParts(parts: Name.currentTimestamp.part)
    }
}
