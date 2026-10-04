//
//  Functions+PostgresJSONB.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let jsonbAgg: Self = .init("jsonb_agg")
    @available(*, deprecated, renamed: "jsonbAgg")
    public static var jsonb_agg: Self { .jsonbAgg }
    public static let toJSONB: Self = .init("to_jsonb")
    @available(*, deprecated, renamed: "toJSONB")
    public static var to_jsonb: Self { .toJSONB }
    public static let jsonbBuildArray: Self = .init("jsonb_build_array")
    @available(*, deprecated, renamed: "jsonbBuildArray")
    public static var jsonb_build_array: Self { .jsonbBuildArray }
    public static let jsonbBuildObject: Self = .init("jsonb_build_object")
    @available(*, deprecated, renamed: "jsonbBuildObject")
    public static var jsonb_build_object: Self { .jsonbBuildObject }
    public static let jsonbObject: Self = .init("jsonb_object")
    @available(*, deprecated, renamed: "jsonbObject")
    public static var jsonb_object: Self { .jsonbObject }
    public static let jsonbArrayLength: Self = .init("jsonb_array_length")
    @available(*, deprecated, renamed: "jsonbArrayLength")
    public static var jsonb_array_length: Self { .jsonbArrayLength }
    public static let jsonbEach: Self = .init("jsonb_each")
    @available(*, deprecated, renamed: "jsonbEach")
    public static var jsonb_each: Self { .jsonbEach }
    public static let jsonbEachText: Self = .init("jsonb_each_text")
    @available(*, deprecated, renamed: "jsonbEachText")
    public static var jsonb_each_text: Self { .jsonbEachText }
    public static let jsonbExtractPath: Self = .init("jsonb_extract_path")
    @available(*, deprecated, renamed: "jsonbExtractPath")
    public static var jsonb_extract_path: Self { .jsonbExtractPath }
    public static let jsonbExtractPathText: Self = .init("jsonb_extract_path_text")
    @available(*, deprecated, renamed: "jsonbExtractPathText")
    public static var jsonb_extract_path_text: Self { .jsonbExtractPathText }
    public static let jsonbObjectKeys: Self = .init("jsonb_object_keys")
    @available(*, deprecated, renamed: "jsonbObjectKeys")
    public static var jsonb_object_keys: Self { .jsonbObjectKeys }
    public static let jsonbPopulateRecord: Self = .init("jsonb_populate_record")
    @available(*, deprecated, renamed: "jsonbPopulateRecord")
    public static var jsonb_populate_record: Self { .jsonbPopulateRecord }
    public static let jsonbPopulateRecordSet: Self = .init("jsonb_populate_recordset")
    @available(*, deprecated, renamed: "jsonbPopulateRecordSet")
    public static var jsonb_populate_recordset: Self { .jsonbPopulateRecordSet }
    public static let jsonbArrayElements: Self = .init("jsonb_array_elements")
    @available(*, deprecated, renamed: "jsonbArrayElements")
    public static var jsonb_array_elements: Self { .jsonbArrayElements }
    public static let jsonbArrayElementsText: Self = .init("jsonb_array_elements_text")
    @available(*, deprecated, renamed: "jsonbArrayElementsText")
    public static var jsonb_array_elements_text: Self { .jsonbArrayElementsText }
    public static let jsonbTypeOf: Self = .init("jsonb_typeof")
    @available(*, deprecated, renamed: "jsonbTypeOf")
    public static var jsonb_typeof: Self { .jsonbTypeOf }
    public static let jsonbToRecord: Self = .init("jsonb_to_record")
    @available(*, deprecated, renamed: "jsonbToRecord")
    public static var jsonb_to_record: Self { .jsonbToRecord }
    public static let jsonbToRecordSet: Self = .init("jsonb_to_recordset")
    @available(*, deprecated, renamed: "jsonbToRecordSet")
    public static var jsonb_to_recordset: Self { .jsonbToRecordSet }
    public static let jsonbStripNulls: Self = .init("jsonb_strip_nulls")
    @available(*, deprecated, renamed: "jsonbStripNulls")
    public static var jsonb_strip_nulls: Self { .jsonbStripNulls }
    public static let jsonbSet: Self = .init("jsonb_set")
    @available(*, deprecated, renamed: "jsonbSet")
    public static var jsonb_set: Self { .jsonbSet }
    public static let jsonbInsert: Self = .init("jsonb_insert")
    @available(*, deprecated, renamed: "jsonbInsert")
    public static var jsonb_insert: Self { .jsonbInsert }
    public static let jsonbPretty: Self = .init("jsonb_pretty")
    @available(*, deprecated, renamed: "jsonbPretty")
    public static var jsonb_pretty: Self { .jsonbPretty }
}

extension Fn {
    ///
        public static func jsonbAgg(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbAgg, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbAgg(_:)")
        public static func jsonb_agg(_ aggregateExpression: SQLable) -> SQLable {
            jsonbAgg(aggregateExpression)
        }
        
        /// Returns the value as jsonb.
        /// Arrays and composites are converted (recursively) to arrays and objects;
        /// otherwise, if there is a cast from the type to json, the cast function will be used to perform the conversion;
        /// otherwise, a scalar value is produced.
        /// For any scalar type other than a number, a Boolean, or a null value,
        /// the text representation will be used, in such a fashion that it is a valid json or jsonb value.
        public static func toJSONB(_ aggregateExpression: SQLable) -> SQLable {
            build(.toJSONB, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "toJSONB(_:)")
        public static func to_jsonb(_ aggregateExpression: SQLable) -> SQLable {
            toJSONB(aggregateExpression)
        }
        
        /// Builds a possibly-heterogeneously-typed JSON array out of a variadic argument list
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbBuildArray(_ items: SQLable...) -> SQLable {
            jsonbBuildArray(items)
        }

        @available(*, deprecated, renamed: "jsonbBuildArray(_:)")
        public static func jsonb_build_array(_ items: SQLable...) -> SQLable {
            jsonbBuildArray(items)
        }
        
        /// Builds a possibly-heterogeneously-typed JSON array out of a variadic argument list
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbBuildArray(_ items: [SQLable]) -> SQLable {
            var parts: [SQLPart] = []
            for (i, v) in items.enumerated() {
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: v.parts)
            }
            return build(.jsonbBuildArray, body: parts)
        }

        @available(*, deprecated, renamed: "jsonbBuildArray(_:)")
        public static func jsonb_build_array(_ items: [SQLable]) -> SQLable {
            jsonbBuildArray(items)
        }
        
        /// Builds a JSON object out of a variadic argument list.
        /// By convention, the argument list consists of alternating keys and values
        /// # Example
        /// ```swift
        /// Fn.jsonbBuildObject("foo", 1, "bar", 2)
        /// ```
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbBuildObject(_ items: SQLable...) -> SQLable {
            jsonbBuildObject(items)
        }

        @available(*, deprecated, renamed: "jsonbBuildObject(_:)")
        public static func jsonb_build_object(_ items: SQLable...) -> SQLable {
            jsonbBuildObject(items)
        }
        
        /// Builds a JSON object out of a variadic argument list.
        /// By convention, the argument list consists of alternating keys and values
        /// # Example
        /// ```swift
        /// Fn.jsonbBuildObject("foo", 1, "bar", 2)
        /// ```
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbBuildObject(_ items: [SQLable]) -> SQLable {
            var parts: [SQLPart] = []
            for (i, v) in items.enumerated() {
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: v.parts)
            }
            return build(.jsonbBuildObject, body: parts)
        }

        @available(*, deprecated, renamed: "jsonbBuildObject(_:)")
        public static func jsonb_build_object(_ items: [SQLable]) -> SQLable {
            jsonbBuildObject(items)
        }
        
        /// Builds a JSON object out of a text array.
        /// The array must have either exactly one dimension with an even number of members,
        /// in which case they are taken as alternating key/value pairs,
        /// or two dimensions such that each inner array has exactly two elements, which are taken as a key/value pair
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbObject(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbObject, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbObject(_:)")
        public static func jsonb_object(_ aggregateExpression: SQLable) -> SQLable {
            jsonbObject(aggregateExpression)
        }
        
        /// This form of json_object takes keys and values pairwise from two separate arrays.
        /// In all other respects it is identical to the one-argument form.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbObject(keys: SQLable, values: SQLable) -> SQLable {
            var parts: [SQLPart] = keys.parts
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: values.parts)
            return build(.jsonbObject, body: parts)
        }

        @available(*, deprecated, renamed: "jsonbObject(keys:values:)")
        public static func jsonb_object(keys: SQLable, values: SQLable) -> SQLable {
            jsonbObject(keys: keys, values: values)
        }
        
        /// Returns the number of elements in the outermost JSON array
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbArrayLength(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbArrayLength, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbArrayLength(_:)")
        public static func jsonb_array_length(_ aggregateExpression: SQLable) -> SQLable {
            jsonbArrayLength(aggregateExpression)
        }
        
        /// Expands the outermost JSON object into a set of key/value pairs
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbEach(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbEach, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbEach(_:)")
        public static func jsonb_each(_ aggregateExpression: SQLable) -> SQLable {
            jsonbEach(aggregateExpression)
        }
        
        /// Expands the outermost JSON object into a set of key/value pairs. The returned values will be of type text
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbEachText(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbEachText, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbEachText(_:)")
        public static func jsonb_each_text(_ aggregateExpression: SQLable) -> SQLable {
            jsonbEachText(aggregateExpression)
        }
        
        /// Returns JSON value pointed to by path_elems (equivalent to #> operator)
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbExtractPath(_ fromJson: SQLable, pathElems: [String]) -> SQLable {
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
            
            return build(.jsonbExtractPath, body: parts)
        }
        
        public static func jsonbExtractPath(_ fromJson: SQLable, pathElems: String...) -> SQLable {
            jsonbExtractPath(fromJson, pathElems: pathElems)
        }

        @available(*, deprecated, renamed: "jsonbExtractPath(_:pathElems:)")
        public static func jsonb_extract_path(_ from_json: SQLable, path_elems: [String]) -> SQLable {
            jsonbExtractPath(from_json, pathElems: path_elems)
        }

        @available(*, deprecated, renamed: "jsonbExtractPath(_:pathElems:)")
        public static func jsonb_extract_path(_ from_json: SQLable, path_elems: String...) -> SQLable {
            jsonbExtractPath(from_json, pathElems: path_elems)
        }
        
        /// Returns JSON value pointed to by path_elems as text (equivalent to #>> operator)
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbExtractPathText(_ fromJson: SQLable, pathElems: [String]) -> SQLable {
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
            
            return build(.jsonbExtractPathText, body: parts)
        }
        
        public static func jsonbExtractPathText(_ fromJson: SQLable, pathElems: String...) -> SQLable {
            jsonbExtractPathText(fromJson, pathElems: pathElems)
        }

        @available(*, deprecated, renamed: "jsonbExtractPathText(_:pathElems:)")
        public static func jsonb_extract_path_text(_ from_json: SQLable, path_elems: [String]) -> SQLable {
            jsonbExtractPathText(from_json, pathElems: path_elems)
        }

        @available(*, deprecated, renamed: "jsonbExtractPathText(_:pathElems:)")
        public static func jsonb_extract_path_text(_ from_json: SQLable, path_elems: String...) -> SQLable {
            jsonbExtractPathText(from_json, pathElems: path_elems)
        }
        
        /// Returns set of keys in the outermost JSON object.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbObjectKeys(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbObjectKeys, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbObjectKeys(_:)")
        public static func jsonb_object_keys(_ aggregateExpression: SQLable) -> SQLable {
            jsonbObjectKeys(aggregateExpression)
        }
        
        /// Expands the object in from_json to a row whose columns match the record type defined by base (see note below).
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbPopulateRecord(base: SQLable, fromJSON: SQLable) -> SQLable {
            var parts: [SQLPart] = base.parts
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: fromJSON.parts)
            return build(.jsonbPopulateRecord, body: parts)
        }

        @available(*, deprecated, renamed: "jsonbPopulateRecord(base:fromJSON:)")
        public static func jsonb_populate_record(base: SQLable, from_json: SQLable) -> SQLable {
            jsonbPopulateRecord(base: base, fromJSON: from_json)
        }
        
        /// Expands the outermost array of objects in from_json to a set of rows whose columns match the record type defined by base (see note below).
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbPopulateRecordSet(base: SQLable, fromJSON: SQLable) -> SQLable {
            var parts: [SQLPart] = base.parts
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: fromJSON.parts)
            return build(.jsonbPopulateRecordSet, body: parts)
        }

        @available(*, deprecated, renamed: "jsonbPopulateRecordSet(base:fromJSON:)")
        public static func jsonb_populate_recordset(base: SQLable, from_json: SQLable) -> SQLable {
            jsonbPopulateRecordSet(base: base, fromJSON: from_json)
        }
        
        /// Expands a JSON array to a set of JSON values.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbArrayElements(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbArrayElements, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbArrayElements(_:)")
        public static func jsonb_array_elements(_ aggregateExpression: SQLable) -> SQLable {
            jsonbArrayElements(aggregateExpression)
        }
        
        /// Expands a JSON array to a set of text values.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbArrayElementsText(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbArrayElementsText, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbArrayElementsText(_:)")
        public static func jsonb_array_elements_text(_ aggregateExpression: SQLable) -> SQLable {
            jsonbArrayElementsText(aggregateExpression)
        }
        
        /// Returns the type of the outermost JSON value as a text string. Possible types are object, array, string, number, boolean, and null.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbTypeOf(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbTypeOf, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbTypeOf(_:)")
        public static func jsonb_typeof(_ aggregateExpression: SQLable) -> SQLable {
            jsonbTypeOf(aggregateExpression)
        }
        
        /// Builds an arbitrary record from a JSON object (see note below). As with all functions returning record, the caller must explicitly define the structure of the record with an AS clause.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbToRecord(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbToRecord, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbToRecord(_:)")
        public static func jsonb_to_record(_ aggregateExpression: SQLable) -> SQLable {
            jsonbToRecord(aggregateExpression)
        }
        
        /// Builds an arbitrary set of records from a JSON array of objects (see note below). As with all functions returning record, the caller must explicitly define the structure of the record with an AS clause.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbToRecordSet(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbToRecordSet, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbToRecordSet(_:)")
        public static func jsonb_to_recordset(_ aggregateExpression: SQLable) -> SQLable {
            jsonbToRecordSet(aggregateExpression)
        }
        
        /// Returns from_json with all object fields that have null values omitted. Other null values are untouched.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbStripNulls(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbStripNulls, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbStripNulls(_:)")
        public static func jsonb_strip_nulls(_ aggregateExpression: SQLable) -> SQLable {
            jsonbStripNulls(aggregateExpression)
        }
        
        /// Returns target with the section designated by path replaced by new_value,
        /// or with new_value added if create_missing is true ( default is true)
        /// and the item designated by path does not exist.
        /// As with the path orientated operators, negative integers
        /// that appear in path count from the end of JSON arrays.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    //    public static func jsonb_set(target: SQLable, path text: [String], new_value: SQLable, create_missing: Bool? = nil) -> SQLable { // TDB
    //        return _buildFn(.jsonb_set, body: aggregateExpression.parts)
    //    }
        
        /// Returns target with new_value inserted.
        /// If target section designated by path is in a JSONB array,
        /// new_value will be inserted before target or after if insert_after is true (default is false).
        /// If target section designated by path is in JSONB object, new_value will be inserted
        /// only if target does not exist. As with the path orientated operators, negative integers
        /// that appear in path count from the end of JSON arrays.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
    //    public static func jsonb_insert(target: SQLable, path text: [String], new_value: SQLable, insert_after: Bool? = nil) -> SQLable { // TDB
    //        return _buildFn(.jsonb_insert, body: aggregateExpression.parts)
    //    }
        
        /// Returns from_json as indented JSON text.
        /// [Learn more →](https://www.postgresql.org/docs/current/functions-json.html)
        public static func jsonbPretty(_ aggregateExpression: SQLable) -> SQLable {
            build(.jsonbPretty, body: aggregateExpression.parts)
        }

        @available(*, deprecated, renamed: "jsonbPretty(_:)")
        public static func jsonb_pretty(_ aggregateExpression: SQLable) -> SQLable {
            jsonbPretty(aggregateExpression)
        }
}
