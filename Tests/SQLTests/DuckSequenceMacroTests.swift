import Testing
@testable import SQL

private final class Task23IdentifierDialect: SQLDialect {
    override func catalogName(_ value: String) -> String { "CAT[\(value)]" }
    override func schemaName(_ value: String) -> String { "SCH[\(value)]" }
    override func tableName(_ value: String) -> String { "TAB[\(value)]" }
    override func column(_ value: String) -> String { "COL[\(value)]" }
    override func alias(_ value: String) -> String { "ALS[\(value)]" }
    override func identifier(_ value: String) -> String { "ID[\(value)]" }
}

private func makeScalarMacro(_ parameter: MacroParameter) -> SwifQLable {
    SwifQL.create.macro[any: Path.Identifier("helper_scalar")]
        .macroParameters(parameter)
        .as(parameter + 1)
}

private func makeTableMacro(_ parameter: MacroParameter) -> SwifQLable {
    SwifQL.create.macro[any: Path.Identifier("helper_rows")]
        .macroParameters(parameter)
        .as.table
        .select(parameter)
}

@Suite("Duck sequences and macros")
struct DuckSequenceMacroTests: SwifQLTests {
    @Test("Sequence atoms and value-bearing options compose mechanically")
    func sequenceAtomsAndClauses() {
        let identifier = Path.Identifier(schema: "analytics", name: "order_id_seq")
        let create = SwifQL.create.sequence[any: identifier]
        let replace = SwifQL.create.or.replace.sequence.if.not.exists[any: identifier]
        let temp = SwifQL.create.temp.sequence[any: Path.Identifier("scratch_seq")]
        let temporary = SwifQL.create.temporary.sequence[any: Path.Identifier("scratch_long")]
        let options = create
            .start(10)
            .start(with: 11)
            .increment(by: -2)
            .minValue(-9)
            .maxValue(99)
            .cycle
        let noOptions = SwifQL.create.sequence[any: identifier]
            .no.minValue
            .no.maxValue
            .no.cycle
        let drop = SwifQL.drop.sequence[any: identifier]
        let dropIfExists = SwifQL.drop.sequence.if.exists[any: identifier].restrict
        let dropCascade = SwifQL.drop.sequence[any: identifier].cascade

        #expect(create.prepare(.duck).plain == #"CREATE SEQUENCE "analytics"."order_id_seq""#)
        #expect(replace.prepare(.duck).plain == #"CREATE OR REPLACE SEQUENCE IF NOT EXISTS "analytics"."order_id_seq""#)
        #expect(temp.prepare(.duck).plain == #"CREATE TEMP SEQUENCE "scratch_seq""#)
        #expect(temporary.prepare(.duck).plain == #"CREATE TEMPORARY SEQUENCE "scratch_long""#)
        #expect(
            options.prepare(.duck).plain ==
                #"CREATE SEQUENCE "analytics"."order_id_seq" START 10 START WITH 11 INCREMENT BY -2 MINVALUE -9 MAXVALUE 99 CYCLE"#
        )
        #expect(
            noOptions.prepare(.duck).plain ==
                #"CREATE SEQUENCE "analytics"."order_id_seq" NO MINVALUE NO MAXVALUE NO CYCLE"#
        )
        #expect(drop.prepare(.duck).plain == #"DROP SEQUENCE "analytics"."order_id_seq""#)
        #expect(dropIfExists.prepare(.duck).plain == #"DROP SEQUENCE IF EXISTS "analytics"."order_id_seq" RESTRICT"#)
        #expect(dropCascade.prepare(.duck).plain == #"DROP SEQUENCE "analytics"."order_id_seq" CASCADE"#)

        var conditional = SwifQL.create.sequence[any: Path.Identifier("conditional")]
        if true {
            conditional = conditional.cycle
        }
        let copied = SwifQLableParts(parts: options.parts)
        let erased: SwifQLable = copied
        let helper = SwifQLableParts(parts: [SwifQLPartOperator.space, .custom("TAIL")])

        #expect(conditional.prepare(.duck).plain == #"CREATE SEQUENCE "conditional" CYCLE"#)
        #expect(erased.prepare(.duck).plain == copied.prepare(.duck).plain)
        #expect((copied ~ helper).prepare(.duck).plain.contains("TAIL"))

        for query in [create, replace, temp, temporary, options, noOptions, drop, dropIfExists, dropCascade] {
            #expect(query.prepare(.duck).splitted.values.isEmpty)
        }
    }

    @Test("nextVal, currVal, DEFAULT, and historical sequence controls preserve binding semantics")
    func sequenceFunctionsAndDefaults() {
        let next = Fn.nextVal("order_id_seq")
        let current = Fn.currVal("order_id_seq")
        let nextPrepared = next.prepare(.duck).splitted
        let currentPrepared = current.prepare(.duck).splitted

        #expect(next.prepare(.duck).plain == "nextval('order_id_seq')")
        #expect(current.prepare(.duck).plain == "currval('order_id_seq')")
        #expect(nextPrepared.query == "nextval($1)")
        #expect(currentPrepared.query == "currval($1)")
        #expect(nextPrepared.values.count == 1)
        #expect(currentPrepared.values.count == 1)
        #expect(nextPrepared.values[0] as? String == "order_id_seq")

        let ordered = SwifQL.select(next, current, "tail").prepare(.duck).splitted
        #expect(ordered.query == "SELECT nextval($1), currval($2), $3")
        #expect(ordered.values.count == 3)
        #expect(ordered.values[0] as? String == "order_id_seq")
        #expect(ordered.values[1] as? String == "order_id_seq")
        #expect(ordered.values[2] as? String == "tail")

        let explicitDefault = SwifQL.default(next)
        #expect(explicitDefault.prepare(.duck).plain == "DEFAULT nextval('order_id_seq')")
        #expect(explicitDefault.prepare(.duck).splitted.query == "DEFAULT nextval($1)")
        #expect(
            NewColumn("id", .integer)
                .default(expression: explicitDefault)
                .prepare(.duck).plain == #""id" integer DEFAULT nextval('order_id_seq')"#
        )
        #expect(
            NewColumn("id", .integer)
                .default(sequence: "nextval('order_id_seq')")
                .prepare(.duck).plain == #""id" integer nextval('order_id_seq')"#
        )

        #expect(Type.auto(from: Int.self, isPrimary: true).name == "serial")
        #expect(Type.auto(from: Int64.self, isPrimary: true).name == "bigserial")
        #expect(NewColumn("id", Type.auto(from: Int.self, isPrimary: true)).prepare(.duck).plain == #""id" serial"#)
        #expect(NewColumn("id", Type.auto(from: Int64.self, isPrimary: true)).prepare(.duck).plain == #""id" bigserial"#)
    }

    @Test("Scalar macros use structural parameters and generic AS expressions")
    func scalarMacros() {
        let x = MacroParameter("x")
        let y = MacroParameter("y")
        let typed = MacroParameter("value", .integer)

        let zero = SwifQL.create.macro[any: Path.Identifier("zero")]
            .macroParameters()
            .as(42)
        let one = SwifQL.create.macro[any: Path.Identifier("twice")]
            .macroParameters(x)
            .as(x * 2)
        let many = SwifQL.create.or.replace.macro.if.not.exists[any: Path.Identifier("sum")]
            .macroParameters(x, y)
            .as(x + y)
        let typedMacro = SwifQL.create.temp.macro[any: Path.Identifier("typed")]
            .macroParameters(typed)
            .as(typed)
        let typedArithmeticMacro = SwifQL.create.macro[any: Path.Identifier("typed_arithmetic")]
            .macroParameters(typed)
            .as(typed + 1)
        let temporary = SwifQL.create.temporary.macro[any: Path.Identifier("temporary")]
            .macroParameters(x)
            .as(x)
        let functionAlias = SwifQL.create.function[any: Path.Identifier("function_alias")]
            .macroParameters(x)
            .as(x)

        #expect(zero.prepare(.duck).plain == #"CREATE MACRO "zero" () as 42"#)
        #expect(one.prepare(.duck).plain == #"CREATE MACRO "twice" ("x") as "x" * 2"#)
        #expect(
            many.prepare(.duck).plain ==
                #"CREATE OR REPLACE MACRO IF NOT EXISTS "sum" ("x", "y") as "x" + "y""#
        )
        #expect(typed.parts.count == 1)
        #expect(typed.parts.first is SwifQLPartIdentifier)
        #expect(typed.prepare(.duck).plain == #""value""#)
        #expect(typedMacro.prepare(.duck).plain == #"CREATE TEMP MACRO "typed" ("value" integer) as "value""#)
        #expect(typedArithmeticMacro.prepare(.duck).plain == #"CREATE MACRO "typed_arithmetic" ("value" integer) as "value" + 1"#)
        #expect(temporary.prepare(.duck).plain == #"CREATE TEMPORARY MACRO "temporary" ("x") as "x""#)
        #expect(functionAlias.prepare(.duck).plain == #"CREATE FUNCTION "function_alias" ("x") as "x""#)

        let body = SwifQL.create.macro[any: Path.Identifier("body")]
            .macroParameters(x)
            .as(x + "literal")
            .prepare(.duck).splitted
        #expect(body.query == #"CREATE MACRO "body" ("x") as "x" + $1"#)
        #expect(body.values.count == 1)
        #expect(body.values[0] as? String == "literal")

        let copied = SwifQLableParts(parts: one.parts)
        var incrementallyErased: SwifQLable = SwifQL.create.macro[any: Path.Identifier("incremental")]
        incrementallyErased = incrementallyErased.macroParameters(x)
        incrementallyErased = incrementallyErased.as(x * 2)
        var conditionalMacro: SwifQLable = SwifQL.create.macro[any: Path.Identifier("conditional")]
        if true {
            conditionalMacro = conditionalMacro.macroParameters(typed)
        }
        conditionalMacro = conditionalMacro.as(typed)
        let helperMacro = makeScalarMacro(typed)
        let helper = SwifQLableParts(parts: [SwifQLPartOperator.space, .custom("TAIL")])
        let erased: SwifQLable = copied
        #expect(erased.prepare(.duck).plain == one.prepare(.duck).plain)
        #expect(incrementallyErased.prepare(.duck).plain == #"CREATE MACRO "incremental" ("x") as "x" * 2"#)
        #expect(conditionalMacro.prepare(.duck).plain == #"CREATE MACRO "conditional" ("value" integer) as "value""#)
        #expect(helperMacro.prepare(.duck).plain == #"CREATE MACRO "helper_scalar" ("value" integer) as "value" + 1"#)
        #expect((copied ~ helper).prepare(.duck).plain.contains("TAIL"))
        #expect(typedMacro.prepare(.duck).splitted.values.isEmpty)
        #expect(typedArithmeticMacro.prepare(.duck).splitted.query == #"CREATE MACRO "typed_arithmetic" ("value" integer) as "value" + $1"#)
        #expect(typedArithmeticMacro.prepare(.duck).splitted.values.count == 1)
        #expect(temporary.prepare(.duck).splitted.values.isEmpty)
        #expect(functionAlias.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Table macros and macro drops stay direct composition")
    func tableMacros() {
        let value = MacroParameter("value", .integer)
        let table = SwifQL.create.macro[any: Path.Identifier("rows")]
            .macroParameters(value)
            .as.table
            .select(value)
        let helperTable = makeTableMacro(value)
        let zero = SwifQL.create.macro[any: Path.Identifier("empty_rows")]
            .macroParameters()
            .as.table
            .select(1)
        let drop = SwifQL.drop.macro[any: Path.Identifier("rows")]
        let dropTable = SwifQL.drop.macro.table[any: Path.Identifier("rows")]
        let dropFunctionAlias = SwifQL.drop.function[any: Path.Identifier("function_alias")]
        let dropRestrict = SwifQL.drop.macro.if.exists[any: Path.Identifier("macro")].restrict
        let dropCascade = SwifQL.drop.macro.if.exists[any: Path.Identifier("missing")].cascade
        let dropTableIfExists = SwifQL.drop.macro.table.if.exists[any: Path.Identifier("rows")]

        #expect(table.prepare(.duck).plain == #"CREATE MACRO "rows" ("value" integer) as TABLE SELECT "value""#)
        #expect(zero.prepare(.duck).plain == #"CREATE MACRO "empty_rows" () as TABLE SELECT 1"#)
        #expect(helperTable.prepare(.duck).plain == #"CREATE MACRO "helper_rows" ("value" integer) as TABLE SELECT "value""#)
        #expect(drop.prepare(.duck).plain == #"DROP MACRO "rows""#)
        #expect(dropTable.prepare(.duck).plain == #"DROP MACRO TABLE "rows""#)
        #expect(dropFunctionAlias.prepare(.duck).plain == #"DROP FUNCTION "function_alias""#)
        #expect(dropRestrict.prepare(.duck).plain == #"DROP MACRO IF EXISTS "macro" RESTRICT"#)
        #expect(dropCascade.prepare(.duck).plain == #"DROP MACRO IF EXISTS "missing" CASCADE"#)
        #expect(dropTableIfExists.prepare(.duck).plain == #"DROP MACRO TABLE IF EXISTS "rows""#)

        let invocation = Fn.call(Path.Identifier("rows"), 21, "tail")
        let query = SwifQL.select(Path.Column("value")).from(invocation)
        let prepared = query.prepare(.duck).splitted
        #expect(query.prepare(.duck).plain == #"SELECT "value" FROM "rows"(21, 'tail')"#)
        #expect(prepared.query == #"SELECT "value" FROM "rows"($1, $2)"#)
        #expect(prepared.values.count == 2)
        #expect(prepared.values[0] as? Int == 21)
        #expect(prepared.values[1] as? String == "tail")

        let copied = SwifQLableParts(parts: table.parts)
        let erased: SwifQLable = copied
        let helper = SwifQLableParts(parts: [SwifQLPartOperator.space, .custom("TAIL")])
        #expect(erased.prepare(.duck).plain == table.prepare(.duck).plain)
        #expect((copied ~ helper).prepare(.duck).plain.contains("TAIL"))
        #expect(helperTable.prepare(.duck).splitted.values.isEmpty)
        for query in [dropFunctionAlias, dropRestrict, dropCascade, dropTableIfExists] {
            #expect(query.prepare(.duck).splitted.values.isEmpty)
        }
    }

    @Test("Identifier-aware calls route through the generic identifier hook")
    func functionCalls() {
        let zero = Fn.call(Path.Identifier("zero"))
        let one = Fn.call(Path.Identifier("one"), 1)
        let many = Fn.call(Path.Identifier("many"), 1, "two", 3)
        let qualified = Fn.call(
            Path.Identifier(catalog: "memory", schema: "analytics", name: "rows"),
            21
        )

        #expect(zero.prepare(.duck).plain == #""zero"()"#)
        #expect(one.prepare(.duck).plain == #""one"(1)"#)
        #expect(many.prepare(.duck).plain == #""many"(1, 'two', 3)"#)
        #expect(qualified.prepare(.duck).plain == #""memory"."analytics"."rows"(21)"#)
        #expect(many.prepare(.duck).splitted.query == #""many"($1, $2, $3)"#)
        #expect(many.prepare(.duck).splitted.values.count == 3)

        #expect(
            qualified.prepare(Task23IdentifierDialect()).plain ==
                "CAT[memory].SCH[analytics].ID[rows](21)"
        )
        let typed = MacroParameter("value", .integer)
        let customMacro = SwifQL.create.macro[any: Path.Identifier("typed")]
            .macroParameters(typed)
            .as(typed)
        #expect(typed.prepare(Task23IdentifierDialect()).plain == "ID[value]")
        #expect(customMacro.prepare(Task23IdentifierDialect()).plain == "CREATE MACRO ID[typed] (ID[value] integer) as ID[value]")
        #expect(Fn.coalesce(1, 2).prepare(.duck).plain == "coalesce(1,2)")
    }
}
