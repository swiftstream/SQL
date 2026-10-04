import Testing
@testable import SQL

private struct Task22Schema: Schemable {
    static var schemaName: String { "task22_schema" }
}

@Suite("Duck schema DDL")
struct DuckSchemaDDLTests: SwifQLTests {
    @Test("Schema builders remain exact while direct schema atoms add verified modifiers")
    func schemaBuildersAndDirectAtoms() {
        #expect(
            CreateSchemaBuilder<Task22Schema>().prepare(.duck).plain ==
                #"CREATE SCHEMA "task22_schema""#
        )
        #expect(
            CreateSchemaBuilder<Task22Schema>()
                .checkIfNotExists()
                .prepare(.duck)
                .plain == #"CREATE SCHEMA IF NOT EXISTS "task22_schema""#
        )
        #expect(
            DropSchemaBuilder<Task22Schema>().prepare(.duck).plain ==
                #"DROP SCHEMA "task22_schema""#
        )
        #expect(
            DropSchemaBuilder<Task22Schema>()
                .checkIfExists()
                .prepare(.duck)
                .plain == #"DROP SCHEMA IF EXISTS "task22_schema""#
        )

        let direct = SwifQL.create.schema[any: Path.Schema("analytics")]
        let replace = SwifQL.create.or.replace.schema[any: Path.Schema("analytics")]
        let dropRestrict = SwifQL.drop.schema[any: Path.Schema("analytics")].restrict
        let dropCascade = SwifQL.drop.schema[any: Path.Schema("analytics")].cascade

        #expect(direct.prepare(.duck).plain == #"CREATE SCHEMA "analytics""#)
        #expect(replace.prepare(.duck).plain == #"CREATE OR REPLACE SCHEMA "analytics""#)
        #expect(dropRestrict.prepare(.duck).plain == #"DROP SCHEMA "analytics" RESTRICT"#)
        #expect(dropCascade.prepare(.duck).plain == #"DROP SCHEMA "analytics" CASCADE"#)
    }

    @Test("Schema names use the existing schema hook and never become binds")
    func schemaNamesAndBindings() {
        let edge = SwifQL.create.schema[any: Path.Schema("select\"schema")]
        let prepared = edge.prepare(.duck)

        #expect(prepared.plain == #"CREATE SCHEMA "select""schema""#)
        #expect(prepared.splitted.query == prepared.plain)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("Direct schema composition survives copy, erasure, and helper assembly")
    func compositionInvariance() {
        let source = SwifQL.create.or.replace.schema[any: Path.Schema("analytics")]
        let copied = SwifQLableParts(parts: source.parts)
        let erased: SwifQLable = copied
        let helperParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let helper = SwifQLableParts(parts: helperParts)
        let composed = source ~ helper

        #expect(copied.prepare(.duck).plain == source.prepare(.duck).plain)
        #expect(erased.prepare(.duck).plain == source.prepare(.duck).plain)
        #expect(composed.prepare(.duck).plain == #"CREATE OR REPLACE SCHEMA "analytics" TAIL"#)
        #expect(source.prepare(.duck).splitted.values.isEmpty)
    }
}
