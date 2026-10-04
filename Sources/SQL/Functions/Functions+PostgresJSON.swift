//
//  Functions+PostgresJSON.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let jsonAgg: Self = .init("json_agg")
    @available(*, deprecated, renamed: "jsonAgg")
    public static var json_agg: Self { .jsonAgg }
    public static let toJSON: Self = .init("to_json")
    @available(*, deprecated, renamed: "toJSON")
    public static var to_json: Self { .toJSON }
    public static let arrayToJSON: Self = .init("array_to_json")
    @available(*, deprecated, renamed: "arrayToJSON")
    public static var array_to_json: Self { .arrayToJSON }
    public static let rowToJSON: Self = .init("row_to_json")
    @available(*, deprecated, renamed: "rowToJSON")
    public static var row_to_json: Self { .rowToJSON }
    public static let jsonBuildArray: Self = .init("json_build_array")
    @available(*, deprecated, renamed: "jsonBuildArray")
    public static var json_build_array: Self { .jsonBuildArray }
    public static let jsonBuildObject: Self = .init("json_build_object")
    @available(*, deprecated, renamed: "jsonBuildObject")
    public static var json_build_object: Self { .jsonBuildObject }
    public static let jsonObject: Self = .init("json_object")
    @available(*, deprecated, renamed: "jsonObject")
    public static var json_object: Self { .jsonObject }
    public static let jsonArrayLength: Self = .init("json_array_length")
    @available(*, deprecated, renamed: "jsonArrayLength")
    public static var json_array_length: Self { .jsonArrayLength }
    public static let jsonEach: Self = .init("json_each")
    @available(*, deprecated, renamed: "jsonEach")
    public static var json_each: Self { .jsonEach }
    public static let jsonEachText: Self = .init("json_each_text")
    @available(*, deprecated, renamed: "jsonEachText")
    public static var json_each_text: Self { .jsonEachText }
    public static let jsonExtractPath: Self = .init("json_extract_path")
    @available(*, deprecated, renamed: "jsonExtractPath")
    public static var json_extract_path: Self { .jsonExtractPath }
    public static let jsonExtractPathText: Self = .init("json_extract_path_text")
    @available(*, deprecated, renamed: "jsonExtractPathText")
    public static var json_extract_path_text: Self { .jsonExtractPathText }
    public static let jsonObjectKeys: Self = .init("json_object_keys")
    @available(*, deprecated, renamed: "jsonObjectKeys")
    public static var json_object_keys: Self { .jsonObjectKeys }
    public static let jsonPopulateRecord: Self = .init("json_populate_record")
    @available(*, deprecated, renamed: "jsonPopulateRecord")
    public static var json_populate_record: Self { .jsonPopulateRecord }
    public static let jsonPopulateRecordSet: Self = .init("json_populate_recordset")
    @available(*, deprecated, renamed: "jsonPopulateRecordSet")
    public static var json_populate_recordset: Self { .jsonPopulateRecordSet }
    public static let jsonArrayElements: Self = .init("json_array_elements")
    @available(*, deprecated, renamed: "jsonArrayElements")
    public static var json_array_elements: Self { .jsonArrayElements }
    public static let jsonArrayElementsText: Self = .init("json_array_elements_text")
    @available(*, deprecated, renamed: "jsonArrayElementsText")
    public static var json_array_elements_text: Self { .jsonArrayElementsText }
    public static let jsonTypeOf: Self = .init("json_typeof")
    @available(*, deprecated, renamed: "jsonTypeOf")
    public static var json_typeof: Self { .jsonTypeOf }
    public static let jsonToRecord: Self = .init("json_to_record")
    @available(*, deprecated, renamed: "jsonToRecord")
    public static var json_to_record: Self { .jsonToRecord }
    public static let jsonToRecordSet: Self = .init("json_to_recordset")
    @available(*, deprecated, renamed: "jsonToRecordSet")
    public static var json_to_recordset: Self { .jsonToRecordSet }
    public static let jsonStripNulls: Self = .init("json_strip_nulls")
    @available(*, deprecated, renamed: "jsonStripNulls")
    public static var json_strip_nulls: Self { .jsonStripNulls }
}

extension Fn {
    ///
    public static func jsonAgg(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonAgg, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonAgg(_:)")
    public static func json_agg(_ aggregateExpression: SQLable) -> SQLable {
        jsonAgg(aggregateExpression)
    }
    
    /// Returns the value as json.
    /// Arrays and composites are converted (recursively) to arrays and objects;
    /// otherwise, if there is a cast from the type to json, the cast function will be used to perform the conversion;
    /// otherwise, a scalar value is produced.
    /// For any scalar type other than a number, a Boolean, or a null value,
    /// the text representation will be used, in such a fashion that it is a valid json or jsonb value.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func toJSON(_ aggregateExpression: SQLable) -> SQLable {
        build(.toJSON, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "toJSON(_:)")
    public static func to_json(_ aggregateExpression: SQLable) -> SQLable {
        toJSON(aggregateExpression)
    }
    
    /// Returns the array as a JSON array.
    /// A PostgreSQL multidimensional array becomes a JSON array of arrays.
    /// Line feeds will be added between dimension-1 elements if pretty_bool is true
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func arrayToJSON(_ anyarray: SQLable, pretty: Bool? = nil) -> SQLable {
        var parts: [SQLPart] = anyarray.parts
        if let pretty = pretty {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(safe: pretty)
        }
        return build(.arrayToJSON, body: parts)
    }

    @available(*, deprecated, renamed: "arrayToJSON(_:pretty:)")
    public static func array_to_json(_ anyarray: SQLable, pretty: Bool? = nil) -> SQLable {
        arrayToJSON(anyarray, pretty: pretty)
    }
    
    /// Returns the row as a JSON object.
    /// Line feeds will be added between level-1 elements if pretty_bool is true
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func rowToJSON(_ record: SQLable, pretty: Bool? = nil) -> SQLable {
        var parts: [SQLPart] = record.parts
        if let pretty = pretty {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(safe: pretty)
        }
        return build(.rowToJSON, body: parts)
    }

    @available(*, deprecated, renamed: "rowToJSON(_:pretty:)")
    public static func row_to_json(_ record: SQLable, pretty: Bool? = nil) -> SQLable {
        rowToJSON(record, pretty: pretty)
    }
    
    /// Builds a possibly-heterogeneously-typed JSON array out of a variadic argument list
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonBuildArray(_ items: SQLable...) -> SQLable {
        jsonBuildArray(items)
    }

    @available(*, deprecated, renamed: "jsonBuildArray(_:)")
    public static func json_build_array(_ items: SQLable...) -> SQLable {
        jsonBuildArray(items)
    }
    
    /// Builds a possibly-heterogeneously-typed JSON array out of a variadic argument list
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonBuildArray(_ items: [SQLable]) -> SQLable {
        var parts: [SQLPart] = []
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return build(.jsonBuildArray, body: parts)
    }

    @available(*, deprecated, renamed: "jsonBuildArray(_:)")
    public static func json_build_array(_ items: [SQLable]) -> SQLable {
        jsonBuildArray(items)
    }
    
    /// Builds a JSON object out of a variadic argument list.
    /// By convention, the argument list consists of alternating keys and values
    /// # Example
    /// ```swift
        /// Fn.jsonBuildObject("foo", 1, "bar", 2)
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonBuildObject(_ items: SQLable...) -> SQLable {
        jsonBuildObject(items)
    }

    @available(*, deprecated, renamed: "jsonBuildObject(_:)")
    public static func json_build_object(_ items: SQLable...) -> SQLable {
        jsonBuildObject(items)
    }
    
    /// Builds a JSON object out of a variadic argument list.
    /// By convention, the argument list consists of alternating keys and values
    /// # Example
    /// ```swift
        /// Fn.jsonBuildObject("foo", 1, "bar", 2)
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonBuildObject(_ items: [SQLable]) -> SQLable {
        var parts: [SQLPart] = []
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return build(.jsonBuildObject, body: parts)
    }

    @available(*, deprecated, renamed: "jsonBuildObject(_:)")
    public static func json_build_object(_ items: [SQLable]) -> SQLable {
        jsonBuildObject(items)
    }
    
    /// Builds a JSON object out of a text array.
    /// The array must have either exactly one dimension with an even number of members,
    /// in which case they are taken as alternating key/value pairs,
    /// or two dimensions such that each inner array has exactly two elements, which are taken as a key/value pair
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonObject(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonObject, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonObject(_:)")
    public static func json_object(_ aggregateExpression: SQLable) -> SQLable {
        jsonObject(aggregateExpression)
    }
    
    /// This form of json_object takes keys and values pairwise from two separate arrays.
    /// In all other respects it is identical to the one-argument form.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonObject(keys: SQLable, values: SQLable) -> SQLable {
        var parts: [SQLPart] = keys.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: values.parts)
        return build(.jsonObject, body: parts)
    }

    @available(*, deprecated, renamed: "jsonObject(keys:values:)")
    public static func json_object(keys: SQLable, values: SQLable) -> SQLable {
        jsonObject(keys: keys, values: values)
    }
    
    /// Returns the number of elements in the outermost JSON array
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonArrayLength(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonArrayLength, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonArrayLength(_:)")
    public static func json_array_length(_ aggregateExpression: SQLable) -> SQLable {
        jsonArrayLength(aggregateExpression)
    }
    
    /// Expands the outermost JSON object into a set of key/value pairs
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonEach(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonEach, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonEach(_:)")
    public static func json_each(_ aggregateExpression: SQLable) -> SQLable {
        jsonEach(aggregateExpression)
    }
    
    /// Expands the outermost JSON object into a set of key/value pairs. The returned values will be of type text
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonEachText(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonEachText, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonEachText(_:)")
    public static func json_each_text(_ aggregateExpression: SQLable) -> SQLable {
        jsonEachText(aggregateExpression)
    }
    
    /// Returns JSON value pointed to by path_elems (equivalent to #> operator)
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonExtractPath(_ fromJson: SQLable, pathElems: [String]) -> SQLable {
        var parts: [SQLPart] = fromJson.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        for (i, v) in pathElems.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        
        return build(.jsonExtractPath, body: parts)
    }
    
    public static func jsonExtractPath(_ fromJson: SQLable, pathElems: String...) -> SQLable {
        jsonExtractPath(fromJson, pathElems: pathElems)
    }

    @available(*, deprecated, renamed: "jsonExtractPath(_:pathElems:)")
    public static func json_extract_path(_ from_json: SQLable, path_elems: [String]) -> SQLable {
        jsonExtractPath(from_json, pathElems: path_elems)
    }

    @available(*, deprecated, renamed: "jsonExtractPath(_:pathElems:)")
    public static func json_extract_path(_ from_json: SQLable, path_elems: String...) -> SQLable {
        jsonExtractPath(from_json, pathElems: path_elems)
    }
    
    /// Returns JSON value pointed to by path_elems as text (equivalent to #>> operator)
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonExtractPathText(_ fromJson: SQLable, pathElems: [String]) -> SQLable {
        var parts: [SQLPart] = fromJson.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        for (i, v) in pathElems.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        
        return build(.jsonExtractPathText, body: parts)
    }
    
    public static func jsonExtractPathText(_ fromJson: SQLable, pathElems: String...) -> SQLable {
        jsonExtractPathText(fromJson, pathElems: pathElems)
    }

    @available(*, deprecated, renamed: "jsonExtractPathText(_:pathElems:)")
    public static func json_extract_path_text(_ from_json: SQLable, path_elems: [String]) -> SQLable {
        jsonExtractPathText(from_json, pathElems: path_elems)
    }

    @available(*, deprecated, renamed: "jsonExtractPathText(_:pathElems:)")
    public static func json_extract_path_text(_ from_json: SQLable, path_elems: String...) -> SQLable {
        jsonExtractPathText(from_json, pathElems: path_elems)
    }
    
    /// Returns set of keys in the outermost JSON object.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonObjectKeys(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonObjectKeys, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonObjectKeys(_:)")
    public static func json_object_keys(_ aggregateExpression: SQLable) -> SQLable {
        jsonObjectKeys(aggregateExpression)
    }
    
    /// Expands the object in from_json to a row whose columns match the record type defined by base (see note below).
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonPopulateRecord(base: SQLable, fromJSON: SQLable) -> SQLable {
        var parts: [SQLPart] = base.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: fromJSON.parts)
        return build(.jsonPopulateRecord, body: parts)
    }

    @available(*, deprecated, renamed: "jsonPopulateRecord(base:fromJSON:)")
    public static func json_populate_record(base: SQLable, from_json: SQLable) -> SQLable {
        jsonPopulateRecord(base: base, fromJSON: from_json)
    }
    
    /// Expands the outermost array of objects in from_json to a set of rows whose columns match the record type defined by base (see note below).
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonPopulateRecordSet(base: SQLable, fromJSON: SQLable) -> SQLable {
        var parts: [SQLPart] = base.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: fromJSON.parts)
        return build(.jsonPopulateRecordSet, body: parts)
    }

    @available(*, deprecated, renamed: "jsonPopulateRecordSet(base:fromJSON:)")
    public static func json_populate_recordset(base: SQLable, from_json: SQLable) -> SQLable {
        jsonPopulateRecordSet(base: base, fromJSON: from_json)
    }
    
    /// Expands a JSON array to a set of JSON values.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonArrayElements(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonArrayElements, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonArrayElements(_:)")
    public static func json_array_elements(_ aggregateExpression: SQLable) -> SQLable {
        jsonArrayElements(aggregateExpression)
    }
    
    /// Expands a JSON array to a set of text values.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonArrayElementsText(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonArrayElementsText, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonArrayElementsText(_:)")
    public static func json_array_elements_text(_ aggregateExpression: SQLable) -> SQLable {
        jsonArrayElementsText(aggregateExpression)
    }
    
    /// Returns the type of the outermost JSON value as a text string. Possible types are object, array, string, number, boolean, and null.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonTypeOf(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonTypeOf, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonTypeOf(_:)")
    public static func json_typeof(_ aggregateExpression: SQLable) -> SQLable {
        jsonTypeOf(aggregateExpression)
    }
    
    /// Builds an arbitrary record from a JSON object (see note below). As with all functions returning record, the caller must explicitly define the structure of the record with an AS clause.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonToRecord(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonToRecord, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonToRecord(_:)")
    public static func json_to_record(_ aggregateExpression: SQLable) -> SQLable {
        jsonToRecord(aggregateExpression)
    }
    
    /// Builds an arbitrary set of records from a JSON array of objects (see note below). As with all functions returning record, the caller must explicitly define the structure of the record with an AS clause.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonToRecordSet(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonToRecordSet, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonToRecordSet(_:)")
    public static func json_to_recordset(_ aggregateExpression: SQLable) -> SQLable {
        jsonToRecordSet(aggregateExpression)
    }
    
    /// Returns from_json with all object fields that have null values omitted. Other null values are untouched.
    /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    public static func jsonStripNulls(_ aggregateExpression: SQLable) -> SQLable {
        build(.jsonStripNulls, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "jsonStripNulls(_:)")
    public static func json_strip_nulls(_ aggregateExpression: SQLable) -> SQLable {
        jsonStripNulls(aggregateExpression)
    }
}
