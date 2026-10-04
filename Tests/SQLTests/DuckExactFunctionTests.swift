@testable import SQL
import Testing

@Suite("Duck exact existing functions")
struct DuckExactFunctionTests: SwifQLTests {
    private func expectDuck(_ query: SwifQLable, _ expected: String) {
        #expect(query.prepare(.duck).plain == expected)
    }

    @Test("General helpers preserve exact Duck function identity and grammar")
    func generalFunctions() {
        expectDuck(
            SwifQL.select(Fn.subStr("abcdef", 2)),
            "SELECT substr('abcdef', 2)"
        )
        expectDuck(
            SwifQL.select(Fn.coalesce("primary", "fallback")),
            "SELECT coalesce('primary','fallback')"
        )

        let blob = Fn.cast("abc", .blob)
        let bits = Fn.cast("101010", .bit)
        expectDuck(
            SwifQL.select(Fn.octetLength(blob)),
            "SELECT octet_length(cast('abc' as blob))"
        )
        expectDuck(
            SwifQL.select(Fn.octetLength(bits)),
            "SELECT octet_length(cast('101010' as bit))"
        )
        expectDuck(
            SwifQL.select(Fn.cast("42", .integer)),
            "SELECT cast('42' as integer)"
        )
        expectDuck(
            SwifQL.select(Fn.cast(.integer, "42", .varchar)),
            "SELECT cast(integer '42' as varchar)"
        )
        expectDuck(
            SwifQL.select(Fn.ifNull("value", "fallback")),
            "SELECT ifnull('value', 'fallback')"
        )
        expectDuck(
            SwifQL.select(Fn.arrayLength(Fn.listValue(10, 20, 30), 1)),
            "SELECT array_length(list_value(10, 20, 30), 1)"
        )
    }

    @Test("Numeric and aggregate helpers preserve exact names")
    func numericFunctions() {
        expectDuck(SwifQL.select(Fn.abs(-5)), "SELECT abs(-5)")
        expectDuck(SwifQL.select(Fn.avg(1)), "SELECT avg(1)")
        expectDuck(SwifQL.select(Fn.ceil(1.2)), "SELECT ceil(1.2)")
        expectDuck(SwifQL.select(Fn.ceiling(1.2)), "SELECT ceiling(1.2)")
        expectDuck(SwifQL.select(Fn.count(1)), "SELECT count(1)")
        expectDuck(SwifQL.select(Fn.floor(1.8)), "SELECT floor(1.8)")
        expectDuck(SwifQL.select(Fn.max(1)), "SELECT max(1)")
        expectDuck(SwifQL.select(Fn.min(1)), "SELECT min(1)")
        expectDuck(SwifQL.select(Fn.mod(7, 3)), "SELECT mod(7, 3)")
        expectDuck(SwifQL.select(Fn.power(2, 3)), "SELECT power(2, 3)")
        expectDuck(SwifQL.select(Fn.random()), "SELECT random()")
        expectDuck(SwifQL.select(Fn.round(2.345)), "SELECT round(2.345)")
        expectDuck(SwifQL.select(Fn.round(2.345, 2)), "SELECT round(2.345, 2)")
        expectDuck(SwifQL.select(Fn.setSeed(0.5)), "SELECT setseed(0.5)")
        expectDuck(SwifQL.select(Fn.sign(-8)), "SELECT sign(-8)")
        expectDuck(SwifQL.select(Fn.sqrt(9)), "SELECT sqrt(9)")
        expectDuck(SwifQL.select(Fn.sum(1)), "SELECT sum(1)")
        expectDuck(SwifQL.select(Fn.arrayAgg(1)), "SELECT array_agg(1)")
        expectDuck(SwifQL.select(Fn.boolAnd(SwifQLPartBool(true))), "SELECT bool_and(TRUE)")
        expectDuck(SwifQL.select(Fn.boolOr(SwifQLPartBool(false))), "SELECT bool_or(FALSE)")
    }

    @Test("Task 12 numeric overloads preserve historical names and add exact identities")
    func numericSignatureMismatchFunctions() {
        let query = SwifQL.select(
            Fn.exp(1),
            Fn.exp(2, 3),
            Fn.div(7, 3),
            Fn.divide(7, 3)
        )

        check(
            query,
            .psql(
                "SELECT exp(1), exp(2, 3), div(7, 3), divide(7, 3)",
                "SELECT exp($1), exp($2, $3), div($4, $5), divide($6, $7)"
            ),
            .mysql(
                "SELECT exp(1), exp(2, 3), div(7, 3), divide(7, 3)",
                "SELECT exp(?), exp(?, ?), div(?, ?), divide(?, ?)"
            ),
            .duck(
                "SELECT exp(1), exp(2, 3), div(7, 3), divide(7, 3)",
                "SELECT exp($1), exp($2, $3), div($4, $5), divide($6, $7)"
            )
        )
    }

    @Test("Task 11 arrayLength and substring reconciliation remains exact reuse")
    func reconciledArrayLengthAndSubstring() {
        let list = Fn.listValue(10, 20, 30)

        expectDuck(
            SwifQL.select(Fn.arrayLength(list)),
            "SELECT array_length(list_value(10, 20, 30), 1)"
        )
        expectDuck(
            SwifQL.select(Fn.arrayLength(list, 1)),
            "SELECT array_length(list_value(10, 20, 30), 1)"
        )
        expectDuck(
            SwifQL.select(Fn.substring("abcdef", from: 2)),
            "SELECT substring('abcdef' FROM 2)"
        )
        expectDuck(
            SwifQL.select(Fn.substring("abcdef", for: 3)),
            "SELECT substring('abcdef' FOR 3)"
        )
        expectDuck(
            SwifQL.select(Fn.substring("abcdef", from: 2, for: 3)),
            "SELECT substring('abcdef' FROM 2 FOR 3)"
        )
    }

    @Test("Current-time keyword properties coexist with historical functions")
    func currentTimeKeywordProperties() {
        let query = SwifQL.select(
            Fn.currentTime,
            Fn.currentTimestamp,
            Fn.currentTime(0),
            Fn.currentTimestamp(0)
        )

        check(
            query,
            .psql(
                "SELECT current_time, current_timestamp, current_time, current_timestamp",
                "SELECT current_time, current_timestamp, current_time, current_timestamp"
            ),
            .mysql(
                "SELECT current_time, current_timestamp, current_time, current_timestamp",
                "SELECT current_time, current_timestamp, current_time, current_timestamp"
            ),
            .duck(
                "SELECT current_time, current_timestamp, current_time, current_timestamp",
                "SELECT current_time, current_timestamp, current_time, current_timestamp"
            )
        )
    }

    @Test("JSON exact overloads preserve historical forms and ordinary binds")
    func jsonSignatureMismatchFunctions() {
        let concreteArray: [String] = ["a", "1"]
        let json = #"{"a":1}"#
        let query = SwifQL.select(
            Fn.jsonObject(Fn.listValue("a", "1")),
            Fn.jsonObject(concreteArray),
            Fn.jsonObject(keys: Fn.listValue("a"), values: Fn.listValue("1")),
            Fn.jsonObject(),
            Fn.jsonObject("a", 1),
            Fn.jsonObject("a", 1, "b", 2),
            Fn.jsonExtractPath(json, pathElems: "a"),
            Fn.jsonExtractPathText(json, pathElems: "a"),
            Fn.jsonExtractPath(json, path: "a"),
            Fn.jsonExtractPathText(json, path: "a")
        )
        let expected = #"SELECT json_object(list_value('a', '1')), json_object('a', '1'), json_object(list_value('a'), list_value('1')), json_object(), json_object('a', 1), json_object('a', 1, 'b', 2), json_extract_path('{"a":1}', 'a'), json_extract_path_text('{"a":1}', 'a'), json_extract_path('{"a":1}', 'a'), json_extract_path_text('{"a":1}', 'a')"#

        check(
            query,
            .psql(expected, "SELECT json_object(list_value($1, $2)), json_object($3, $4), json_object(list_value($5), list_value($6)), json_object(), json_object($7, $8), json_object($9, $10, $11, $12), json_extract_path($13, $14), json_extract_path_text($15, $16), json_extract_path($17, $18), json_extract_path_text($19, $20)"),
            .mysql(expected, "SELECT json_object(list_value(?, ?)), json_object(?, ?), json_object(list_value(?), list_value(?)), json_object(), json_object(?, ?), json_object(?, ?, ?, ?), json_extract_path(?, ?), json_extract_path_text(?, ?), json_extract_path(?, ?), json_extract_path_text(?, ?)"),
            .duck(expected, "SELECT json_object(list_value($1, $2)), json_object($3, $4), json_object(list_value($5), list_value($6)), json_object(), json_object($7, $8), json_object($9, $10, $11, $12), json_extract_path($13, $14), json_extract_path_text($15, $16), json_extract_path($17, $18), json_extract_path_text($19, $20)")
        )

        let bound = SwifQL.select(
            Fn.jsonObject("O'Reilly", "Привет 🦆"),
            Fn.jsonExtractPath(json, path: "a")
        ).prepare(.duck)
        #expect(bound.plain == "SELECT json_object('O''Reilly', 'Привет 🦆'), json_extract_path('{\"a\":1}', 'a')")
        #expect(bound.splitted.query == "SELECT json_object($1, $2), json_extract_path($3, $4)")
        #expect(bound.splitted.values.map { $0 as? String } == ["O'Reilly", "Привет 🦆", json, "a"])
    }

    @Test("Existing one-argument JSON reuse stays exact while pretty forms remain unclaimed")
    func existingJSONOneArgumentReuse() {
        expectDuck(
            SwifQL.select(Fn.arrayToJSON(Fn.listValue(1, 2))),
            "SELECT array_to_json(list_value(1, 2))"
        )
        expectDuck(
            SwifQL.select(Fn.rowToJSON(Fn.listValue(1, 2))),
            "SELECT row_to_json(list_value(1, 2))"
        )
        expectDuck(
            SwifQL.select(Fn.arrayToJSON(Fn.listValue(1, 2), pretty: true)),
            "SELECT array_to_json(list_value(1, 2), TRUE)"
        )
        expectDuck(
            SwifQL.select(Fn.rowToJSON(Fn.listValue(1, 2), pretty: true)),
            "SELECT row_to_json(list_value(1, 2), TRUE)"
        )
    }

    @Test("Aggregate helpers compose in a real aggregate query")
    func aggregateComposition() {
        let table = Path.Table("aggregate_values")
        let value = table.column("value")
        let query = SwifQL
            .select(
                Fn.avg(value),
                Fn.count(value),
                Fn.max(value),
                Fn.min(value),
                Fn.sum(value),
                Fn.arrayAgg(value),
                Fn.boolAnd(SwifQLPartBool(true)),
                Fn.boolOr(SwifQLPartBool(false)),
                Fn.stringAgg(value, "-")
            )
            .from(table)

        expectDuck(
            query,
            #"SELECT avg("aggregate_values"."value"), count("aggregate_values"."value"), max("aggregate_values"."value"), min("aggregate_values"."value"), sum("aggregate_values"."value"), array_agg("aggregate_values"."value"), bool_and(TRUE), bool_or(FALSE), string_agg("aggregate_values"."value", '-') FROM "aggregate_values""#
        )
    }

    @Test("String helpers preserve exact names and current grammar")
    func stringFunctions() {
        expectDuck(SwifQL.select(Fn.bitLength("jose")), "SELECT bit_length('jose')")
        expectDuck(SwifQL.select(Fn.charLength("jose")), "SELECT char_length('jose')")
        expectDuck(SwifQL.select(Fn.characterLength("jose")), "SELECT character_length('jose')")
        expectDuck(SwifQL.select(Fn.concat("Post", "greSQL")), "SELECT concat('Post', 'greSQL')")
        expectDuck(SwifQL.select(Fn.concatWS("-", "Post", "greSQL")), "SELECT concat_ws('-', 'Post', 'greSQL')")
        expectDuck(SwifQL.select(Fn.length("jose")), "SELECT length('jose')")
        expectDuck(SwifQL.select(Fn.lower("JOSE")), "SELECT lower('JOSE')")
        expectDuck(SwifQL.select(Fn.lPad("hi", 5, "x")), "SELECT lpad('hi', 5, 'x')")
        expectDuck(SwifQL.select(Fn.lTrim("xxalpha", "x")), "SELECT ltrim('xxalpha', 'x')")
        expectDuck(SwifQL.select(Fn.position("ifq", in: "swifql")), "SELECT position('ifq' IN 'swifql')")
        expectDuck(SwifQL.select(Fn.repeat("ab", 3)), "SELECT repeat('ab', 3)")
        expectDuck(SwifQL.select(Fn.replace("abcabc", "ab", "X")), "SELECT replace('abcabc', 'ab', 'X')")
        expectDuck(SwifQL.select(Fn.rPad("hi", 5, "x")), "SELECT rpad('hi', 5, 'x')")
        expectDuck(SwifQL.select(Fn.rTrim("alphaxx", "x")), "SELECT rtrim('alphaxx', 'x')")
        expectDuck(SwifQL.select(Fn.strPos("swifql", "ifq")), "SELECT strpos('swifql', 'ifq')")
        expectDuck(SwifQL.select(Fn.substring("abcdef", from: 2)), "SELECT substring('abcdef' FROM 2)")
        expectDuck(SwifQL.select(Fn.substring("abcdef", for: 3)), "SELECT substring('abcdef' FOR 3)")
        expectDuck(SwifQL.select(Fn.substring("abcdef", from: 2, for: 3)), "SELECT substring('abcdef' FROM 2 FOR 3)")
        expectDuck(SwifQL.select(Fn.translate("12345", "14", "ax")), "SELECT translate('12345', '14', 'ax')")
        expectDuck(SwifQL.select(Fn.trim("  alpha  ")), "SELECT trim('  alpha  ')")
        expectDuck(SwifQL.select(Fn.upper("jose")), "SELECT upper('jose')")
        expectDuck(SwifQL.select(Fn.stringAgg("a", "-")), "SELECT string_agg('a', '-')")
        expectDuck(
            SwifQL.select(Fn.regExpReplace("abc123", "[0-9]+", "#")),
            "SELECT regexp_replace('abc123', '[0-9]+', '#')"
        )
    }

    @Test("Series helpers preserve exact integer call shapes")
    func seriesFunctions() {
        expectDuck(
            SwifQL.select(Fn.generateSeries(1, 4)),
            "SELECT generate_series(1, 4)"
        )
        expectDuck(
            SwifQL.select(Fn.generateSeries(1, 4, 2)),
            "SELECT generate_series(1, 4, 2)"
        )
    }

    @Test("Date and time helpers preserve exact current grammar")
    func dateTimeFunctions() {
        let timestamp = Fn.cast("2001-02-16 20:38:40", .timestamp)
        let date = Fn.cast("2020-01-02", .date)

        expectDuck(SwifQL.select(Fn.age(timestamp)), "SELECT age(cast('2001-02-16 20:38:40' as timestamp))")
        expectDuck(
            SwifQL.select(Fn.age(timestamp, Fn.cast("1957-06-13 00:00:00", .timestamp))),
            "SELECT age(cast('2001-02-16 20:38:40' as timestamp), cast('1957-06-13 00:00:00' as timestamp))"
        )
        expectDuck(
            SwifQL.select(Fn.datePart("year", timestamp)),
            "SELECT date_part('year', cast('2001-02-16 20:38:40' as timestamp))"
        )
        expectDuck(
            SwifQL.select(Fn.dateTrunc("hour", timestamp)),
            "SELECT date_trunc('hour', cast('2001-02-16 20:38:40' as timestamp))"
        )
        expectDuck(
            SwifQL.select(Fn.extract(.year, from: timestamp)),
            "SELECT extract('YEAR' FROM cast('2001-02-16 20:38:40' as timestamp))"
        )
        expectDuck(
            SwifQL.select(Fn.extract("year", from: timestamp)),
            "SELECT extract('year' FROM cast('2001-02-16 20:38:40' as timestamp))"
        )
        expectDuck(SwifQL.select(Fn.isFinite(date)), "SELECT isfinite(cast('2020-01-02' as date))")
        expectDuck(SwifQL.select(Fn.makeDate(2013, 7, 15)), "SELECT make_date(2013, 7, 15)")
        expectDuck(SwifQL.select(Fn.makeTime(8, 15, 23.5)), "SELECT make_time(8, 15, 23.5)")
        expectDuck(
            SwifQL.select(Fn.makeTimestamp(2013, 7, 15, 8, 15, 23.5)),
            "SELECT make_timestamp(2013, 7, 15, 8, 15, 23.5)"
        )
        expectDuck(
            SwifQL.select(Fn.makeTimestampTZ(2013, 7, 15, 8, 15, 23.5)),
            "SELECT make_timestamptz(2013, 7, 15, 8, 15, 23.5)"
        )
        expectDuck(
            SwifQL.select(Fn.makeTimestampTZ(2013, 7, 15, 8, 15, 23.5, "UTC")),
            "SELECT make_timestamptz(2013, 7, 15, 8, 15, 23.5, 'UTC')"
        )
        expectDuck(SwifQL.select(Fn.now()), "SELECT now()")
        expectDuck(SwifQL.select(Fn.currentDate), "SELECT current_date")
        expectDuck(SwifQL.select(Fn.localTime), "SELECT localtime")
        expectDuck(SwifQL.select(Fn.localTimestamp), "SELECT localtimestamp")
        expectDuck(SwifQL.select(Fn.transactionTimestamp()), "SELECT transaction_timestamp()")
        expectDuck(SwifQL.select(Fn.toTimestamp(1284352323.0)), "SELECT to_timestamp(1284352323.0)")
    }

    @Test("Window helpers compose in a real OVER query")
    func windowFunctions() {
        let table = Path.Table("window_values")
        let group = table.column("grp")
        let value = table.column("value")
        func ordered(_ expression: SwifQLable) -> SwifQLable {
            expression.over(partitionBy: group, orderBy: .asc(value))
        }

        let query = SwifQL
            .select(
                ordered(Fn.rowNumber()),
                ordered(Fn.rank()),
                ordered(Fn.denseRank()),
                ordered(Fn.percentRank()),
                ordered(Fn.cumeDist()),
                ordered(Fn.nTile(2)),
                ordered(Fn.lag(value)),
                ordered(Fn.lag(value, 1)),
                ordered(Fn.lead(value)),
                ordered(Fn.lead(value, 1)),
                ordered(Fn.firstValue(value)),
                ordered(Fn.lastValue(value)),
                ordered(Fn.nthValue(value, 2))
            )
            .from(table)

        expectDuck(
            query,
            #"SELECT row_number() OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), rank() OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), dense_rank() OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), percent_rank() OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), cume_dist() OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), ntile(2) OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), lag("window_values"."value") OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), lag("window_values"."value", 1) OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), lead("window_values"."value") OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), lead("window_values"."value", 1) OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), first_value("window_values"."value") OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), last_value("window_values"."value") OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC), nth_value("window_values"."value", 2) OVER (PARTITION BY "window_values"."grp" ORDER BY "window_values"."value" ASC) FROM "window_values""#
        )
    }

    @Test("Argument bindings preserve order and exact function identity")
    func bindings() {
        let first = "O'Reilly"
        let second = "Привет 🦆"
        let query = SwifQL.select(Fn.coalesce(first, second), Fn.subStr("abcdef", 2))
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == "SELECT coalesce('O''Reilly','Привет 🦆'), substr('abcdef', 2)")
        #expect(prepared.splitted.query == "SELECT coalesce($1,$2), substr($3, 2)")
        #expect(prepared.splitted.values.map { $0 as? String } == [first, second, "abcdef"])
    }

    @Test("Copied and stored exact helpers keep the same Duck structure")
    func compositionInvariance() {
        func helper() -> SwifQLable {
            Fn.coalesce("primary", Fn.subStr("fallback", 2))
        }

        let stored: SwifQLable = helper()
        let copied = SwifQLableParts(parts: stored.parts)
        let expected = "SELECT coalesce('primary',substr('fallback', 2))"

        #expect(SwifQL.select(stored).prepare(.duck).plain == expected)
        #expect(SwifQL.select(copied).prepare(.duck).plain == expected)
    }

    @Test("Deliberately unclaimed shapes remain unchanged and explicitly visible")
    func unclaimedInventory() {
        #expect(SwifQL.select(Fn.isNull(1, 2)).prepare(.duck).plain == "SELECT isnull(1, 2)")
        #expect(SwifQL.select(Fn.nvl(1, 2)).prepare(.duck).plain == "SELECT nvl(1, 2)")
        #expect(SwifQL.select(Fn.div(7, 3)).prepare(.duck).plain == "SELECT div(7, 3)")
        #expect(SwifQL.select(Fn.exp(2, 3)).prepare(.duck).plain == "SELECT exp(2, 3)")
        #expect(SwifQL.select(Fn.currentTime(0)).prepare(.duck).plain == "SELECT current_time")
        #expect(SwifQL.select(Fn.currentTimestamp(0)).prepare(.duck).plain == "SELECT current_timestamp")
        #expect(SwifQL.select(Fn.trim(leading: "x", from: "xxalpha")).prepare(.duck).plain == "SELECT trim('xxalpha')")

    }

    @Test("Representative PostgreSQL and MySQL function output remains byte-for-byte stable")
    func establishedDialectRegression() {
        let query = SwifQL.select(
            Fn.abs(-5),
            Fn.subStr("abcdef", 2),
            Fn.stringAgg(CarBrands.column("name"), ", ")
        )

        check(
            query,
            .psql(#"SELECT abs(-5), substr('abcdef', 2), string_agg("CarBrands"."name", ', ')"#),
            .mysql("SELECT abs(-5), substr('abcdef', 2), string_agg(CarBrands.name, ', ')"),
            .duck(#"SELECT abs(-5), substr('abcdef', 2), string_agg("CarBrands"."name", ', ')"#)
        )
    }
}
