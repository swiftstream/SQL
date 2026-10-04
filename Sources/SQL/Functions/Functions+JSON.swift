//
//  Functions+JSON.swift
//  SwifQL
//

import Foundation

extension Fn.Name {
    public static let jsonArray: Self = .init("json_array")
    public static let jsonMergePatch: Self = .init("json_merge_patch")
    public static let jsonGroupArray: Self = .init("json_group_array")
    public static let jsonGroupObject: Self = .init("json_group_object")
    public static let jsonGroupStructure: Self = .init("json_group_structure")
    public static let jsonKeys: Self = .init("json_keys")
    public static let jsonStructure: Self = .init("json_structure")
    public static let jsonType: Self = .init("json_type")
    public static let jsonValid: Self = .init("json_valid")
    public static let jsonValue: Self = .init("json_value")
    public static let jsonTransform: Self = .init("json_transform")
    public static let fromJSON: Self = .init("from_json")
    public static let jsonTransformStrict: Self = .init("json_transform_strict")
    public static let fromJSONStrict: Self = .init("from_json_strict")
    public static let jsonTree: Self = .init("json_tree")
}

extension Fn {
    private static func commaSeparated(_ values: [SQLable]) -> [SQLPart] {
        var parts: [SQLPart] = []
        for (index, value) in values.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: value.parts)
        }
        return parts
    }

    /// Builds DuckDB's variadic `json_array` function.
    public static func jsonArray(_ values: SQLable...) -> SQLable {
        jsonArray(values)
    }

    public static func jsonArray(_ values: [SQLable]) -> SQLable {
        build(.jsonArray, body: commaSeparated(values))
    }

    /// Applies one JSON merge patch to a JSON value.
    public static func jsonMergePatch(_ json: SQLable, _ patch: SQLable) -> SQLable {
        build(.jsonMergePatch, body: commaSeparated([json, patch]))
    }

    /// Builds a DuckDB JSON object from alternating string keys and values.
    public static func jsonObject(_ items: SQLable...) -> SQLable {
        build(.jsonObject, body: commaSeparated(items))
    }

    /// Aggregates values into a JSON array.
    public static func jsonGroupArray(_ value: SQLable) -> SQLable {
        build(.jsonGroupArray, body: value.parts)
    }

    /// Aggregates key/value pairs into a JSON object.
    public static func jsonGroupObject(_ key: SQLable, _ value: SQLable) -> SQLable {
        build(.jsonGroupObject, body: commaSeparated([key, value]))
    }

    /// Aggregates values into a JSON structure description.
    public static func jsonGroupStructure(_ value: SQLable) -> SQLable {
        build(.jsonGroupStructure, body: value.parts)
    }

    public static func jsonKeys(_ json: SQLable) -> SQLable {
        build(.jsonKeys, body: json.parts)
    }

    public static func jsonKeys(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonKeys, body: commaSeparated([json, path]))
    }

    public static func jsonStructure(_ json: SQLable) -> SQLable {
        build(.jsonStructure, body: json.parts)
    }

    public static func jsonType(_ json: SQLable) -> SQLable {
        build(.jsonType, body: json.parts)
    }

    public static func jsonType(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonType, body: commaSeparated([json, path]))
    }

    public static func jsonValid(_ json: SQLable) -> SQLable {
        build(.jsonValid, body: json.parts)
    }

    public static func jsonValue(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonValue, body: commaSeparated([json, path]))
    }

    public static func jsonTransform(_ json: SQLable, structure: SQLable) -> SQLable {
        build(.jsonTransform, body: commaSeparated([json, structure]))
    }

    public static func fromJSON(_ json: SQLable, structure: SQLable) -> SQLable {
        build(.fromJSON, body: commaSeparated([json, structure]))
    }

    public static func jsonTransformStrict(_ json: SQLable, structure: SQLable) -> SQLable {
        build(.jsonTransformStrict, body: commaSeparated([json, structure]))
    }

    public static func fromJSONStrict(_ json: SQLable, structure: SQLable) -> SQLable {
        build(.fromJSONStrict, body: commaSeparated([json, structure]))
    }

    public static func jsonTree(_ json: SQLable) -> SQLable {
        build(.jsonTree, body: json.parts)
    }

    public static func jsonTree(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonTree, body: commaSeparated([json, path]))
    }

    /// Extracts one DuckDB JSON path expression from a JSON value.
    public static func jsonExtractPath(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonExtractPath, body: commaSeparated([json, path]))
    }

    /// Extracts one DuckDB JSON path expression as text.
    public static func jsonExtractPathText(_ json: SQLable, path: SQLable) -> SQLable {
        build(.jsonExtractPathText, body: commaSeparated([json, path]))
    }
}
