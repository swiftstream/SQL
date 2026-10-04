import Testing
@testable import SQL

private struct Task21Table: Table, Schemable {
    static var tableName: String { "task21_table" }
    static var schemaName: String { "ddl_schema" }

    init() {}
}

private struct Task21Parent: Table, Schemable {
    static var tableName: String { "task21_parent" }
    static var schemaName: String { "ddl_schema" }

    init() {}
}

private func appendDirect(_ base: SwifQLable, _ parts: [SwifQLPart]) -> SwifQLable {
    base.structurallyAppending(SwifQLableParts(parts: parts))
}

private func updateTable(_ build: (UpdateTableBuilder<Task21Table>) -> Void) -> SwifQLable {
    let builder = UpdateTableBuilder<Task21Table>()
    build(builder)
    return builder
}

@Suite("Duck table DDL classification")
struct DuckTableDDLTests: SwifQLTests {
    @Test("Create-table builders preserve exact source shapes and safe defaults")
    func createTableBuilderSurface() {
        let constraintCheck = Constraint.check(
            name: "score_positive",
            SwifQLBool(true) == SwifQLBool(true)
        )
        let references = Constraint.references(
            Task21Parent.self,
            onDelete: .restrict,
            onUpdate: .noAction
        )
        let builder = CreateTableBuilder<Task21Table>()
            .column(NewColumn("id", .integer).primaryKey())
            .column(
                "name",
                .text,
                ColumnDefault.default(7 as Any),
                .notNull
            )
            .column(
                NewColumn("score", .integer)
                    .unique()
                    .constraint(expression: constraintCheck.query)
            )
            .column(
                NewColumn("parent_id", .integer)
                    .constraint(expression: references.query)
            )

        #expect(
            builder.prepare(.duck).plain ==
                #"CREATE TABLE "ddl_schema"."task21_table" ("id" integer PRIMARY KEY, "name" text DEFAULT 7 NOT NULL, "score" integer UNIQUE CONSTRAINT "score_positive" CHECK (TRUE = TRUE), "parent_id" integer REFERENCES "ddl_schema"."task21_parent" ON DELETE RESTRICT ON UPDATE NO ACTION)"#
        )
        #expect(builder.prepare(.duck).splitted.values.isEmpty)

        let ifNotExists = CreateTableBuilder<Task21Table>()
            .checkIfNotExists()
            .column("id", .integer)
        #expect(
            ifNotExists.prepare(.duck).plain ==
                #"CREATE TABLE IF NOT EXISTS "ddl_schema"."task21_table" ("id" integer)"#
        )

        let historicalDefault = CreateTableBuilder<Task21Table>()
            .column(NewColumn("value", .integer).default(constant: 7))
        #expect(
            historicalDefault.prepare(.duck).plain ==
                #"CREATE TABLE "ddl_schema"."task21_table" ("value" integer 7)"#
        )

        let historicalStringCheck = CreateTableBuilder<Task21Table>()
            .column(NewColumn("value", .integer).check("value > 0"))
        let preparedStringCheck = historicalStringCheck.prepare(.duck)
        #expect(
            preparedStringCheck.plain ==
                #"CREATE TABLE "ddl_schema"."task21_table" ("value" integer CHECK('value > 0'))"#
        )
        #expect(preparedStringCheck.splitted.query.contains("CHECK($1)"))
        #expect(preparedStringCheck.splitted.values.count == 1)

        let sequenceDefault = CreateTableBuilder<Task21Table>()
            .column(NewColumn("value", .integer).default(sequence: "nextval('seq')"))
        #expect(
            sequenceDefault.prepare(.duck).plain ==
                #"CREATE TABLE "ddl_schema"."task21_table" ("value" integer nextval('seq'))"#
        )
    }

    @Test("CREATE-time referential-action siblings remain exact mechanical SQL")
    func createReferentialActionSiblings() {
        let actions: [(String, ReferentialAction)] = [
            ("NO ACTION", .noAction),
            ("RESTRICT", .restrict),
            ("CASCADE", .cascade),
            ("SET NULL", .setNull),
            ("SET DEFAULT", .setDefault)
        ]

        for (sql, action) in actions {
            let deleteConstraint = Constraint.references(
                Task21Parent.self,
                onDelete: action
            )
            let deleteQuery = SwifQL.create.table[any: Path.Table("fk_table")]
                .tableDefinitions(
                    NewColumn("parent_id", .integer)
                        .constraint(expression: deleteConstraint.query)
                )
            #expect(
                deleteQuery.prepare(.duck).plain ==
                    "CREATE TABLE \"fk_table\" (\"parent_id\" integer REFERENCES \"ddl_schema\".\"task21_parent\" ON DELETE \(sql))"
            )
            #expect(deleteQuery.prepare(.duck).splitted.values.isEmpty)

            let updateConstraint = Constraint.references(
                Task21Parent.self,
                onUpdate: action
            )
            let updateQuery = SwifQL.create.table[any: Path.Table("fk_table")]
                .tableDefinitions(
                    NewColumn("parent_id", .integer)
                        .constraint(expression: updateConstraint.query)
                )
            #expect(
                updateQuery.prepare(.duck).plain ==
                    "CREATE TABLE \"fk_table\" (\"parent_id\" integer REFERENCES \"ddl_schema\".\"task21_parent\" ON UPDATE \(sql))"
            )
            #expect(updateQuery.prepare(.duck).splitted.values.isEmpty)
        }
    }

    @Test("CTAS, OR REPLACE CTAS, and ALTER TYPE use direct generic composition")
    func directSqlComposition() {
        let source = Path.Table("source_table")
        let target = Path.SchemaWithTable(schema: "ddl_schema", table: "copy_table")
        let ctas = SwifQL.create.table[any: target]
            .as
            .select(source.column("id"), source.column("name"))
            .from(source)
        #expect(
            ctas.prepare(.duck).plain ==
                #"CREATE TABLE "ddl_schema"."copy_table" as SELECT "source_table"."id", "source_table"."name" FROM "source_table""#
        )

        let atomicReplace = SwifQL.create.or.replace.table[any: Path.Table("copy_table")]
            .as
            .select(source.column("id"))
            .from(source)
        #expect(
            atomicReplace.prepare(.duck).plain ==
                #"CREATE OR REPLACE TABLE "copy_table" as SELECT "source_table"."id" FROM "source_table""#
        )

        let copied = SwifQLableParts(parts: atomicReplace.parts)
        #expect(copied.prepare(.duck).plain == atomicReplace.prepare(.duck).plain)
        #expect(copied.prepare(.duck).splitted.values.isEmpty)

        let alterType = SwifQL.alter.table[any: Path.Table("task21_table")]
            .alter
            .column[any: Path.Column("score")]
            .type(.varchar)
        let alterSetType = SwifQL.alter.table[any: Path.Table("task21_table")]
            .alter
            .column[any: Path.Column("score")]
            .set
            .type(.integer)
        let alter = SwifQL.alter.table[any: Path.Table("task21_table")]
            .alter
            .column[any: Path.Column("score")]
            .set
            .data
            .type(.varchar)
            .using(
                Path.Column("score").structurallyAppending(
                    SwifQLableParts(parts: [SwifQLPartOperator("::VARCHAR")])
                )
            )
        #expect(
            alterType.prepare(.duck).plain ==
                #"ALTER TABLE "task21_table" ALTER COLUMN "score" TYPE varchar"#
        )
        #expect(
            alterSetType.prepare(.duck).plain ==
                #"ALTER TABLE "task21_table" ALTER COLUMN "score" SET TYPE integer"#
        )
        #expect(
            alter.prepare(.duck).plain ==
                #"ALTER TABLE "task21_table" ALTER COLUMN "score" SET DATA TYPE varchar USING "score"::VARCHAR"#
        )
        #expect(alter.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Generated columns remain generic SQL-shaped boundaries")
    func generatedColumnBoundaries() {
        let expression = Path.Column("a") + 1
        let inferred = SwifQL.create.table[any: Path.Table("generated_table")]
            .tableDefinitions(GeneratedColumn("b", as: expression))
        let explicitVirtual = SwifQL.create.table[any: Path.Table("generated_table")]
            .tableDefinitions(
                GeneratedColumn(
                    "c",
                    .integer,
                    generatedAlwaysAs: expression,
                    storage: .virtual
                )
            )
        let defaultVirtual = SwifQL.create.table[any: Path.Table("generated_table")]
            .tableDefinitions(
                GeneratedColumn("d", .integer, generatedAlwaysAs: expression)
            )
        let stored = SwifQL.create.table[any: Path.Table("generated_table")]
            .tableDefinitions(
                GeneratedColumn(
                    "e",
                    .integer,
                    generatedAlwaysAs: expression,
                    storage: .stored
                )
            )
        let mixed = SwifQL.create.table[any: Path.Table("generated_table")]
            .tableDefinitions([
                NewColumn("base", .integer),
                GeneratedColumn("derived", as: Path.Column("base") + 1),
                GeneratedColumn(
                    "typed",
                    .integer,
                    generatedAlwaysAs: Path.Column("base") + 2,
                    storage: .virtual
                )
            ])

        #expect(
            inferred.prepare(.duck).plain ==
                #"CREATE TABLE "generated_table" ("b" as ("a" + 1))"#
        )
        #expect(
            explicitVirtual.prepare(.duck).plain ==
                #"CREATE TABLE "generated_table" ("c" integer GENERATED ALWAYS as ("a" + 1) VIRTUAL)"#
        )
        #expect(
            defaultVirtual.prepare(.duck).plain ==
                #"CREATE TABLE "generated_table" ("d" integer GENERATED ALWAYS as ("a" + 1))"#
        )
        #expect(
            stored.prepare(.duck).plain ==
                #"CREATE TABLE "generated_table" ("e" integer GENERATED ALWAYS as ("a" + 1) STORED)"#
        )
        #expect(
            mixed.prepare(.duck).plain ==
                #"CREATE TABLE "generated_table" ("base" integer, "derived" as ("base" + 1), "typed" integer GENERATED ALWAYS as ("base" + 2) VIRTUAL)"#
        )
        #expect(inferred.prepare(.duck).splitted.query.contains("$1"))
        #expect(inferred.prepare(.duck).splitted.values.count == 1)
        #expect(mixed.prepare(.duck).splitted.values.map { String(describing: $0) } == ["1", "2"])
        #expect(!inferred.prepare(.duck).plain.contains("Duck"))
    }

    @Test("Structural identifiers and ColumnDefault values stay bind-free")
    func structuralIdentifiersAndDefaults() {
        let builder = CreateTableBuilder<Task21Table>(schema: "quoted schema")
            .column(
                "quoted column",
                .text,
                ColumnDefault.default("O'Reilly" as Any)
            )
        let prepared = builder.prepare(.duck)
        #expect(
            prepared.plain ==
                #"CREATE TABLE "quoted schema"."task21_table" ("quoted column" text DEFAULT 'O''Reilly')"#
        )
        #expect(prepared.splitted.values.isEmpty)

        let direct = SwifQL.create.table[any: Path.SchemaWithTable(
            schema: "quoted schema",
            table: "quoted table"
        )]
        let directParts = appendDirect(
            direct,
            [
                SwifQLPartOperator.space,
                SwifQLPartOperator.openBracket,
                SwifQLPartColumn("quoted column"),
                SwifQLPartOperator.space,
                SwifQLPartOperator("text"),
                SwifQLPartOperator.closeBracket
            ]
        )
        #expect(
            directParts.prepare(.duck).plain ==
                #"CREATE TABLE "quoted schema"."quoted table" ("quoted column" text)"#
        )
        #expect(directParts.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Every current UpdateTableBuilder action keeps its historical rendering")
    func updateTableActions() {
        let combined = updateTable { builder in
            _ = builder
                .addColumn("extra", .text, checkIfNotExists: true)
                .setDefault("extra", constant: "x")
                .setNotNull("extra")
                .dropNotNull("extra")
                .dropDefault("extra")
                .addUnique(to: "id")
                .addPrimaryKey(to: "id")
                .addCheck(SwifQLBool(true) == SwifQLBool(true))
                .addCheck(constraintName: "named_check", SwifQLBool(true) == SwifQLBool(true))
                .addForeignKey(
                    column: "id",
                    constraintName: "task21_fk",
                    schema: "ddl_schema",
                    table: "task21_parent",
                    columns: "id",
                    onDelete: .restrict,
                    onUpdate: .noAction
                )
                .renameColumn("extra", to: "renamed")
                .dropConstraint("task21_fk")
        }
        let combinedPlain = combined.prepare(.duck).plain
        #expect(combinedPlain.contains(#"ADD COLUMN IF NOT EXISTS "extra" text"#))
        #expect(combinedPlain.contains(#"ALTER COLUMN "extra" SET DEFAULT 'x'"#))
        #expect(combinedPlain.contains(#"ADD UNIQUE ("id")"#))
        #expect(combinedPlain.contains(#"ADD PRIMARY KEY ("id")"#))
        #expect(combinedPlain.contains(#"ADD CHECK (TRUE = TRUE)"#))
        #expect(combinedPlain.contains(#"ADD CONSTRAINT "named_check" CHECK (TRUE = TRUE)"#))
        #expect(combinedPlain.contains(#"ADD CONSTRAINT "task21_fk" FOREIGN KEY ("id") REFERENCES "ddl_schema"."task21_parent"("id") ON DELETE RESTRICT ON UPDATE NO ACTION"#))
        #expect(combinedPlain.contains(#"ALTER TABLE "ddl_schema"."task21_table" RENAME COLUMN "extra" TO "renamed";"#))
        #expect(combinedPlain.hasSuffix(#"DROP CONSTRAINT "task21_fk";"#))
        #expect(combined.prepare(.duck).splitted.values.isEmpty)

        let individual = updateTable { builder in
            _ = builder
                .addColumn("extra", .integer)
                .dropColumn("old", checkIfExists: true, cascade: true)
                .setDefault("extra", expression: SwifQLBool(true))
                .dropDefault("extra")
                .setNotNull("extra")
                .dropNotNull("extra")
                .renameColumn("extra", to: "renamed")
                .renameTable(to: "task21_renamed")
        }
        let individualPlain = individual.prepare(.duck).plain
        #expect(individualPlain.contains(#"ADD COLUMN "extra" integer"#))
        #expect(individualPlain.contains(#"DROP COLUMN IF EXISTS "old" CASCADE"#))
        #expect(individualPlain.contains(#"SET DEFAULT TRUE"#))
        #expect(individualPlain.contains(#"DROP DEFAULT"#))
        #expect(individualPlain.contains(#"SET NOT NULL"#))
        #expect(individualPlain.contains(#"DROP NOT NULL"#))
        #expect(individualPlain.contains(#"RENAME COLUMN "extra" TO "renamed";"#))
        #expect(individualPlain.hasSuffix(#"RENAME TO "task21_renamed";"#))

        let psql = UpdateTableBuilder<Task21Table>().addColumn("id", .integer)
        let mysql = UpdateTableBuilder<Task21Table>().addColumn("id", .integer)
        #expect(psql.prepare(.psql).plain == #"ALTER TABLE "ddl_schema"."task21_table" ADD COLUMN "id" integer;"#)
        #expect(mysql.prepare(.mysql).plain == #"ALTER TABLE ddl_schema.task21_table ADD COLUMN id integer;"#)
    }
}
