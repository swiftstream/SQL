import Testing
@testable import SQL

@Suite("Expression Frontier PostgreSQL Range Tests")
struct ExpressionFrontierRangeTests: SwifQLTests {
    @Test("PostgreSQL range scalar functions render exact names")
    func scalarFunctions() {
        let range = SQL.raw("int4range(1, 5)")

        check(Fn.isEmpty(range), .psql("isempty(int4range(1, 5))"))
        check(Fn.lowerInc(range), .psql("lower_inc(int4range(1, 5))"))
        check(Fn.upperInc(range), .psql("upper_inc(int4range(1, 5))"))
        check(Fn.lowerInf(range), .psql("lower_inf(int4range(1, 5))"))
        check(Fn.upperInf(range), .psql("upper_inf(int4range(1, 5))"))
    }

    @Test("rangeMerge supports two ranges and one multirange")
    func rangeMerge() {
        check(
            Fn.rangeMerge(SQL.raw("int4range(1, 3)"), SQL.raw("int4range(5, 8)")),
            .psql("range_merge(int4range(1, 3), int4range(5, 8))")
        )
        check(
            Fn.rangeMerge(SQL.raw("int4multirange(int4range(1, 3))")),
            .psql("range_merge(int4multirange(int4range(1, 3)))")
        )
    }

    @Test("multirange and unnest use exact PostgreSQL function names")
    func multiRangeAndUnNest() {
        check(
            Fn.multiRange(SQL.raw("int4range(1, 3)")),
            .psql("multirange(int4range(1, 3))")
        )
        check(
            Fn.unNest(SQL.raw("int4multirange(int4range(1, 3))")),
            .psql("unnest(int4multirange(int4range(1, 3)))")
        )
    }

    @Test("rangeAgg supports concise and builder forms")
    func rangeAggForms() {
        check(Fn.rangeAgg(SQL.raw("period")), .psql("range_agg(period)"))
        check(Fn.rangeAgg { SQL.raw("period") }, .psql("range_agg(period)"))
        check(Fn.rangeAgg { Distinct(SQL.raw("period")) }, .psql("range_agg(DISTINCT period)"))
        check(
            Fn.rangeAgg { SQL.raw("period"); OrderBy(SQL.raw("sort_key"), .asc) },
            .psql("range_agg(period ORDER BY sort_key ASC)")
        )
        check(Fn.rangeAgg {}, .psql("range_agg()"))
    }

    @Test("rangeIntersectAgg supports concise and builder forms")
    func rangeIntersectAggForms() {
        check(
            Fn.rangeIntersectAgg(SQL.raw("period")),
            .psql("range_intersect_agg(period)")
        )
        check(
            Fn.rangeIntersectAgg { SQL.raw("period") },
            .psql("range_intersect_agg(period)")
        )
        check(
            Fn.rangeIntersectAgg { Distinct(SQL.raw("period")) },
            .psql("range_intersect_agg(DISTINCT period)")
        )
        check(
            Fn.rangeIntersectAgg { SQL.raw("period"); OrderBy(SQL.raw("sort_key"), .asc) },
            .psql("range_intersect_agg(period ORDER BY sort_key ASC)")
        )
        check(Fn.rangeIntersectAgg {}, .psql("range_intersect_agg()"))
    }

    @Test("multirange and polymorphic Type names are exact")
    func typeNames() {
        let identities: [(Type, String)] = [
            (.int4MultiRange, "int4multirange"),
            (.int8MultiRange, "int8multirange"),
            (.numMultiRange, "nummultirange"),
            (.tsMultiRange, "tsmultirange"),
            (.tsTZMultiRange, "tstzmultirange"),
            (.dateMultiRange, "datemultirange"),
            (.anyMultiRange, "anymultirange"),
            (.anyCompatible, "anycompatible"),
            (.anyCompatibleArray, "anycompatiblearray"),
            (.anyCompatibleNonArray, "anycompatiblenonarray"),
            (.anyCompatibleRange, "anycompatiblerange"),
            (.anyCompatibleMultiRange, "anycompatiblemultirange"),
        ]

        for (type, name) in identities {
            #expect(type.name == name)
        }

        #expect(Type.int4range.name == "int4range")
        #expect(Type.int8range.name == "int8range")
        #expect(Type.numrange.name == "numrange")
        #expect(Type.tsrange.name == "tsrange")
        #expect(Type.tstzrange.name == "tstzrange")
        #expect(Type.daterange.name == "daterange")
    }

    @Test("grouped PostgreSQL range operators preserve exact operator tokens")
    func specializedOperators() {
        let lhs = SQL.raw("left_range")
        let rhs = SQL.raw("right_range")

        let cases: [(String, SQLable)] = [
            ("&&", lhs.op(.custom("&&"), rhs)),
            ("<<", lhs.op(.custom("<<"), rhs)),
            (">>", lhs.op(.custom(">>"), rhs)),
            ("&<", lhs.op(.custom("&<"), rhs)),
            ("&>", lhs.op(.custom("&>"), rhs)),
            ("-|-", lhs.op(.custom("-|-"), rhs)),
        ]

        for (symbol, expression) in cases {
            check(expression, .psql("(left_range \(symbol) right_range)"))
        }
    }

    @Test("existing PostgreSQL range operators retain their SQL")
    func existingOperators() {
        let lhs = SQL.raw("left_range")
        let rhs = SQL.raw("right_range")

        check(lhs + rhs, .psql("left_range + right_range"))
        check(lhs * rhs, .psql("left_range * right_range"))
        check(lhs - rhs, .psql("left_range - right_range"))
        check(lhs ||> rhs, .psql("left_range @> right_range"))
        check(lhs <|| rhs, .psql("left_range <@ right_range"))
    }

    @Test("range function binds follow SQL source order")
    func functionBindingOrder() {
        let lhs = "lhs-range"
        let rhs = "rhs-range"
        let query = Fn.rangeMerge(lhs, rhs)
        let prepared = query.prepare(.psql)

        #expect(prepared.plain == "range_merge('lhs-range', 'rhs-range')")
        #expect(prepared.splitted.query == "range_merge($1, $2)")
        #expect(prepared.splitted.values.count == 2)
        #expect(prepared.splitted.values[0] as? String == lhs)
        #expect(prepared.splitted.values[1] as? String == rhs)

        let multiple = SQL.select(Fn.multiRange("first"), Fn.unNest("second")).prepare(.psql)
        #expect(multiple.splitted.query == "SELECT multirange($1), unnest($2)")
        #expect(multiple.splitted.values.count == 2)
        #expect(multiple.splitted.values[0] as? String == "first")
        #expect(multiple.splitted.values[1] as? String == "second")
    }

    @Test("aggregate argument and local ORDER BY bindings preserve source order")
    func aggregateBindingOrder() {
        let argument = "aggregate-range"
        let ordering = "order-range"
        let query = Fn.rangeAgg {
            argument
            OrderBy(ordering, .asc)
        }
        let prepared = query.prepare(.psql)

        #expect(prepared.plain == "range_agg('aggregate-range' ORDER BY 'order-range' ASC)")
        #expect(prepared.splitted.query == "range_agg($1 ORDER BY $2 ASC)")
        #expect(prepared.splitted.values.count == 2)
        #expect(prepared.splitted.values[0] as? String == argument)
        #expect(prepared.splitted.values[1] as? String == ordering)
    }

    @Test("specialized operator binds lhs before rhs")
    func operatorBindingOrder() {
        let lhs = "lhs-range"
        let rhs = "rhs-range"
        let prepared = lhs.op(.custom("&&"), rhs).prepare(.psql)

        #expect(prepared.plain == "('lhs-range' && 'rhs-range')")
        #expect(prepared.splitted.query == "($1 && $2)")
        #expect(prepared.splitted.values.count == 2)
        #expect(prepared.splitted.values[0] as? String == lhs)
        #expect(prepared.splitted.values[1] as? String == rhs)
    }
}
