@testable import SQL
import Testing

@Suite("Other Tests")
struct OtherTests: SwifQLTests {
    // MARK: String enum array
    
    @Test("Test String Enum Array")
    func stringEnumArray() {
        enum UserRole: String, SwifQLEnum {
            case admin
            case staff
            case vendor
        }
        check(
            SwifQL.in([UserRole.admin, .staff, .vendor]),
            .psql(#"IN ('admin', 'staff', 'vendor')"#),
            .mysql(#"IN ('admin', 'staff', 'vendor')"#),
            .duck(#"IN ('admin', 'staff', 'vendor')"#)
        )
    }
    
    // MARK: Int enum array
    
    @Test("Test Int Enum Array")
    func intEnumArray() {
        enum UserRole: Int, SwifQLEnum {
            case admin = 0
            case staff = 1
            case vendor = 2
        }
        check(
            SwifQL.in([UserRole.admin, .staff, .vendor]),
            .psql(#"IN (0, 1, 2)"#),
            .mysql(#"IN (0, 1, 2)"#),
            .duck(#"IN (0, 1, 2)"#)
        )
    }
    
    // MARK: Int enum value alone
    
    @Test("Test Int Enum Array With Alone Value")
    func intEnumValueAlone() {
        enum UserRole: Int, SwifQLEnum {
            case admin = 0
            case staff = 1
            case vendor = 2
        }
        check(
            0 == UserRole.admin,
            .psql(#"0 = 0"#),
            .mysql(#"0 = 0"#),
            .duck(#"0 = 0"#)
        )
    }
    
    // MARK: String enum value alone
    
    @Test("Test String Enum Array With Value Alone")
    func stringEnumValueAlone() {
        enum UserRole: String, SwifQLEnum {
            case admin
            case staff
            case vendor
        }
        check(
            "admin" == UserRole.admin,
            .psql(#"'admin' = 'admin'"#),
            .mysql(#"'admin' = 'admin'"#),
            .duck(#"'admin' = 'admin'"#)
        )
    }

    // MARK: Null Condition
    
    @Test("Test Null Condition")
    func nullCondition() {
        check(
            "hello" == SwifQLNull,
            .psql(#"'hello' = NULL"#),
            .mysql(#"'hello' = NULL"#),
            .duck(#"'hello' = NULL"#)
        )
        check(
            "hello" == nil,
            .psql(#"'hello' IS NULL"#),
            .mysql(#"'hello' IS NULL"#),
            .duck(#"'hello' IS NULL"#)
        )
    }
    
    // MARK: Enum array
    
    @Test("Test Enum Array")
    func enumArray() {
        check(
            [GearboxType.manual],
            .psql(#"'{manual}'"#),
            .mysql(#"'{manual}'"#)
        )
        check(
            [GearboxType.manual, .auto],
            .psql(#"'{manual,auto}'"#),
            .mysql(#"'{manual,auto}'"#)
        )
    }
    
    // MARK: Enum array type autodetect
    
    @Test("Test Array Type Autodetect")
    func enumArrayTypeAutodetect() {
        #expect(Type.auto(from: [GearboxType].self).name == "gearboxtype[]")
    }
    
    // MARK: ANY operator
    
    @Test("Test Operator")
    func anyOperator() {
        check(
            SwifQL.any("hello"),
            .psql(#"ANY('hello')"#),
            .mysql(#"ANY('hello')"#)
        )
    }
    
    // MARK: Update
    
    @Test("Test Update With Schema")
    func updateWithSchema() {
        let alias = CarBrands.inSchema("hello")
        check(
            SwifQL.update(alias.table).set[items: alias.$id == 1, alias.$createdAt == 2],
            .psql(#"UPDATE "hello"."CarBrands" SET "id" = 1, "createdAt" = 2"#),
            .mysql(#"UPDATE hello.CarBrands SET id = 1, createdAt = 2"#),
            .duck(#"UPDATE "hello"."CarBrands" SET "id" = 1, "createdAt" = 2"#)
        )
    }
    
    @Test("Test Update Already Schemable With Different Schema")
    func updateAlreadySchemableWithDifferentSchema() {
        let alias = SchemableCarBrands.inSchema("hello")
        check(
            SwifQL.update(alias.table).set[items: alias.$id == 1, alias.$createdAt == 2],
            .psql(#"UPDATE "hello"."CarBrands" SET "id" = 1, "createdAt" = 2"#),
            .mysql(#"UPDATE hello.CarBrands SET id = 1, createdAt = 2"#),
            .duck(#"UPDATE "hello"."CarBrands" SET "id" = 1, "createdAt" = 2"#)
        )
    }
    
    // MARK: Alias
    
    @Test("Test Alias")
    func alias() {
        check(
            CarBrands.as("c"),
            .psql(#""c""#),
            .mysql(#"c"#),
            .duck(#""c""#)
        )
        check(
            CarBrands.as("c").$id,
            .psql(#""c"."id""#),
            .mysql(#"c.id"#),
            .duck(#""c"."id""#)
        )
        check(
            CarBrands.as("c").table,
            .psql(#""CarBrands" AS "c""#),
            .mysql(#"CarBrands AS c"#),
            .duck(#""CarBrands" AS "c""#)
        )
        check(
            SchemableCarBrands.as("c").table,
            .psql(#""public"."CarBrands" AS "c""#),
            .mysql(#"public.CarBrands AS c"#),
            .duck(#""public"."CarBrands" AS "c""#)
        )
    }
    
    // MARK: Create Type
    
    @Test("Test Create Type")
    func createType() {
        check(
            SwifQL.type("mood"),
            .psql(#"TYPE "mood""#),
            .mysql(#"TYPE mood"#)
        )
        check(
            SwifQL.type("trololo", "mood"),
            .psql(#"TYPE "trololo"."mood""#),
            .mysql(#"TYPE trololo.mood"#)
        )
    }
    
    // MARK: Select enum
    
    private enum Mood: String, SwifQLEnum {
        case sad, happy
    }
    
    @Test("Test Select Enum")
    func selectEnum() {
        check(
            SwifQL.select(Mood.happy),
            .psql(#"SELECT 'happy'"#),
            .mysql(#"SELECT 'happy'"#),
            .duck(#"SELECT 'happy'"#)
        )
    }
    
    // MARK: Rename Table
    
    @Test("Test Rename Table")
    func renameTable() {
        check(UpdateTableBuilder<CarBrands>().renameTable(to: "aaa"),
              .psql(#"ALTER TABLE "CarBrands" RENAME TO "aaa";"#), .duck(#"ALTER TABLE "CarBrands" RENAME TO "aaa";"#))
    }
    
    // MARK: Add Column
    
    @Test("Test Add Column")
    func addColumn() {
        check(UpdateTableBuilder<CarBrands>().addColumn("aaa", .bigint, .default(0), .notNull),
              .psql(#"ALTER TABLE "CarBrands" ADD COLUMN "aaa" bigint DEFAULT 0 NOT NULL;"#))
    }

    @Test("Test Add Column If Not Exits")
    func addColumnIfNotExits() {
        check(UpdateTableBuilder<CarBrands>().addColumn("aaa", .bigint, .default(0), checkIfNotExists: true, .notNull),
              .psql(#"ALTER TABLE "CarBrands" ADD COLUMN IF NOT EXISTS "aaa" bigint DEFAULT 0 NOT NULL;"#))
    }

    // MARK: Drop Column
    
    @Test("Test Drop Column")
    func dropColumn() {
        check(UpdateTableBuilder<CarBrands>().dropColumn("aaa"),
              .psql(#"ALTER TABLE "CarBrands" DROP COLUMN "aaa";"#), .duck(#"ALTER TABLE "CarBrands" DROP COLUMN "aaa";"#))
    }

    @Test("Test Drop Column If Exists")
    func dropColumnIfExists() {
        check(UpdateTableBuilder<CarBrands>().dropColumn("aaa", checkIfExists: true),
              .psql(#"ALTER TABLE "CarBrands" DROP COLUMN IF EXISTS "aaa";"#), .duck(#"ALTER TABLE "CarBrands" DROP COLUMN IF EXISTS "aaa";"#))
    }

    @Test("Test Drop Column Cascade")
    func dropColumnCascade() {
        check(UpdateTableBuilder<CarBrands>().dropColumn("aaa", cascade: true),
              .psql(#"ALTER TABLE "CarBrands" DROP COLUMN "aaa" CASCADE;"#), .duck(#"ALTER TABLE "CarBrands" DROP COLUMN "aaa" CASCADE;"#))
    }

    @Test("Test Drop Column If Exists Cascade")
    func dropColumnIfExistsCascade() {
        check(UpdateTableBuilder<CarBrands>().dropColumn("aaa", checkIfExists: true, cascade: true),
              .psql(#"ALTER TABLE "CarBrands" DROP COLUMN IF EXISTS "aaa" CASCADE;"#), .duck(#"ALTER TABLE "CarBrands" DROP COLUMN IF EXISTS "aaa" CASCADE;"#))
    }

    // MARK: Set Default
    
    @Test("Test Set Default")
    func setDefault() {
        check(UpdateTableBuilder<CarBrands>().setDefault("aaa", constant: 0),
              .psql(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" SET DEFAULT 0;"#), .duck(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" SET DEFAULT 0;"#))
    }
    
    // MARK: Drop Default
    
    @Test("Test Drop Default")
    func dropDefault() {
        check(UpdateTableBuilder<CarBrands>().dropDefault("aaa"),
              .psql(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" DROP DEFAULT;"#), .duck(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" DROP DEFAULT;"#))
    }
    
    // MARK: Set Not Null
    
    @Test("Test Set Not Null")
    func setNotNull() {
        check(UpdateTableBuilder<CarBrands>().setNotNull("aaa"),
              .psql(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" SET NOT NULL;"#), .duck(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" SET NOT NULL;"#))
    }
    
    // MARK: Drop Not Null
    
    @Test("Test Drop Not Null")
    func dropNotNull() {
        check(UpdateTableBuilder<CarBrands>().dropNotNull("aaa"),
              .psql(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" DROP NOT NULL;"#), .duck(#"ALTER TABLE "CarBrands" ALTER COLUMN "aaa" DROP NOT NULL;"#))
    }
    
    // MARK: Rename Column
    
    @Test("Test Rename Column")
    func renameColumn() {
        check(UpdateTableBuilder<CarBrands>().renameColumn("aaa", to: "bbb"),
              .psql(#"ALTER TABLE "CarBrands" RENAME COLUMN "aaa" TO "bbb";"#), .duck(#"ALTER TABLE "CarBrands" RENAME COLUMN "aaa" TO "bbb";"#))
    }
    
    // MARK: Add Unique
    
    @Test("Test Add Unique")
    func addUnique() {
        check(UpdateTableBuilder<CarBrands>().addUnique(to: "aaa", "bbb"),
              .psql(#"ALTER TABLE "CarBrands" ADD UNIQUE ("aaa", "bbb");"#))
    }
    
    // MARK: Add Primary Key
    
    @Test("Test Add Primary Key")
    func addPrimaryKey() {
        check(UpdateTableBuilder<CarBrands>().addPrimaryKey(to: "aaa", "bbb"),
              .psql(#"ALTER TABLE "CarBrands" ADD PRIMARY KEY ("aaa", "bbb");"#), .duck(#"ALTER TABLE "CarBrands" ADD PRIMARY KEY ("aaa", "bbb");"#))
    }
    
    // MARK: Drop Constraint
    
    @Test("Test Drop Constraint")
    func dropConstraint() {
        check(UpdateTableBuilder<CarBrands>().dropConstraint("aaa"),
              .psql(#"DROP CONSTRAINT "aaa";"#))
    }
    
    // MARK: Drop Index
    
    @Test("Test Drop Index")
    func dropIndex() {
        check(UpdateTableBuilder<CarBrands>().dropIndex(name: "aaa"),
              .psql(#"DROP INDEX "aaa";"#))
    }
    
    // MARK: Create Index
    
    @Test("Test Create Index")
    func createIndex() {
        check(
            UpdateTableBuilder<CarBrands>().createIndex(
                unique: true,
                name: "aaa",
                items: .column("column3", order: .desc),
                       .expression(SwifQLBool(true) == SwifQLBool(true)),
                type: .hash,
                where: SwifQLBool(true) == SwifQLBool(true)
            ),
            .psql(#"CREATE UNIQUE INDEX "aaa" ON "CarBrands" USING HASH ("column3" DESC, (TRUE = TRUE)) WHERE TRUE = TRUE;"#)
        )
    }
    
    // MARK: Add Check
    
    @Test("Test Add Check")
    func addCheck() {
        check(UpdateTableBuilder<CarBrands>().addCheck(constraintName: "some_check", SwifQLBool(true) == SwifQLBool(false)),
              .psql(#"ALTER TABLE "CarBrands" ADD CONSTRAINT "some_check" CHECK (TRUE = FALSE);"#))
    }
    
    // MARK: Add Foreign Key
    
    @Test("Test Add Foreign Key")
    func addForeignKey() {
        check(UpdateTableBuilder<CarBrands>().addForeignKey(column: "aaa", constraintName: "fk_aaa", schema: "deleted", table: "User", columns: "id", onDelete: .cascade, onUpdate: .noAction),
              .psql(#"ALTER TABLE "CarBrands" ADD CONSTRAINT "fk_aaa" FOREIGN KEY ("aaa") REFERENCES "deleted"."User"("id") ON DELETE CASCADE ON UPDATE NO ACTION;"#))
    }
    
    //MARK: - Operators
    
    @Test("Test Operator To SwifQLable")
    func operatorToSwifQLable() {
        check(SwifQL.select(Operator.null), .mysql("SELECT NULL"), .psql("SELECT NULL"), .duck("SELECT NULL"))
    }
        
    //MARK: - ARRAY
    
    @Test("Test Array")
    func array() {
        let emptyIntArray: [Int] = []
        check(
            emptyIntArray,
//            .mysql(""),
            .psql("")
        )
        check(
            SwifQLableParts(parts: emptyIntArray),
//            .mysql("''"),
            .psql("'{}'")
        )

        let nonEmptyIntArray: [Int] = [1,3,7]
        check(
            nonEmptyIntArray,
//            .mysql("1, 3, 7"),
            .psql("1, 3, 7")
        )
        check(
            SwifQLableParts(parts: nonEmptyIntArray),
//            .mysql("'1,3,7'"),
            .psql("ARRAY[1,3,7]", "ARRAY[$1,$2,$3]")
        )
        
        let emptyStringArray: [Int] = []
        check(
            emptyStringArray,
//            .mysql(""),
            .psql("")
        )
        check(
            SwifQLableParts(parts: emptyStringArray),
//            .mysql("''"),
            .psql("'{}'")
        )

        let nonEmptyStringArray: [String] = ["a", "b", "c"]
        check(
            nonEmptyStringArray,
//            .mysql("'a', 'b', 'c'"),
            .psql("'a', 'b', 'c'")
        )
        check(
            SwifQLableParts(parts: nonEmptyStringArray),
//            .mysql("'a','b','c'"),
            .psql("ARRAY['a','b','c']", "ARRAY[$1,$2,$3]")
        )
    }
    
    //MARK: - WHERE
    
    @Test("Test Where")
    func `where`() {
        check(SwifQL.where("" == 1), all: "WHERE '' = 1")
        check(SwifQL.where, all: "WHERE")
    }
    
    //MARK: - UNION
    
    @Test("Test Union")
    func union() {
        let table1 = Path.Table("Table1")
        let table2 = Path.Table("Table2")
        let table3 = Path.Table("Table3")
        check(
            Union(
                SwifQL.select(table1.*).from(table1),
                SwifQL.select(table2.*).from(table2),
                SwifQL.select(table3.*).from(table3)
            ),
            .psql(#"(SELECT "Table1".* FROM "Table1") UNION (SELECT "Table2".* FROM "Table2") UNION (SELECT "Table3".* FROM "Table3")"#),
            .mysql(#"(SELECT Table1.* FROM Table1) UNION (SELECT Table2.* FROM Table2) UNION (SELECT Table3.* FROM Table3)"#),
            .duck(#"(SELECT "Table1".* FROM "Table1") UNION (SELECT "Table2".* FROM "Table2") UNION (SELECT "Table3".* FROM "Table3")"#)
        )
        
        check(
            SwifQL
                .select(Distinct(Path.Column("uniqueName")) => .text => "name")
                .from(
                    Union(
                        SwifQL.select(Distinct(Path.Column("name")) => .text => "uniqueName").from(table1),
                        SwifQL.select(Distinct(Path.Column("name")) => .text => "uniqueName").from(table2)
                    )
            ),
            .psql(#"SELECT DISTINCT "uniqueName"::text as "name" FROM (SELECT DISTINCT "name"::text as "uniqueName" FROM "Table1") UNION (SELECT DISTINCT "name"::text as "uniqueName" FROM "Table2")"#),
            .mysql(#"SELECT DISTINCT uniqueName::text as name FROM (SELECT DISTINCT name::text as uniqueName FROM Table1) UNION (SELECT DISTINCT name::text as uniqueName FROM Table2)"#),
            .duck(#"SELECT DISTINCT "uniqueName"::text as "name" FROM (SELECT DISTINCT "name"::text as "uniqueName" FROM "Table1") UNION (SELECT DISTINCT "name"::text as "uniqueName" FROM "Table2")"#)
        )
    }

    //MARK: - VALUES
    
    @Test("Test Values")
    func values() {
        check(
            SwifQL.values(1, 1.2, 1.234, "hello"),
            .psql("(1, 1.2, 1.234, 'hello')"),
            .mysql("(1, 1.2, 1.234, 'hello')"),
            .duck("(1, 1.2, 1.234, 'hello')")
        )
        check(
            SwifQL.values(array: [1, 1.2, 1.234, "hello"], [2, 2.3, 2.345, "bye"]),
            .psql("(1, 1.2, 1.234, 'hello'), (2, 2.3, 2.345, 'bye')"),
            .mysql("(1, 1.2, 1.234, 'hello'), (2, 2.3, 2.345, 'bye')"),
            .duck("(1, 1.2, 1.234, 'hello'), (2, 2.3, 2.345, 'bye')")
        )
    }
    
    // MARK: - BINDINGS
    
    @Test("Test Binding For PostgreSQL")
    func bindingForPostgreSQL() {
        let query = SwifQL.where(CarBrands.column("name") == "hello" || CarBrands.column("name") == "world").prepare(.psql).splitted.query
        #expect(query == """
        WHERE "CarBrands"."name" = $1 OR "CarBrands"."name" = $2
        """)
        #expect(SwifQL.where(CarBrands.column("name") == "hello" || CarBrands.column("name") == "world").prepare(.duck).splitted.query == """
        WHERE "CarBrands"."name" = $1 OR "CarBrands"."name" = $2
        """)
    }
    
    @Test("Test Binding For MySQL")
    func bindingForMySQL() {
        let query = SwifQL.where(CarBrands.column("name") == "hello" || CarBrands.column("name") == "world").prepare(.mysql).splitted.query
        #expect(query == """
        WHERE CarBrands.name = ? OR CarBrands.name = ?
        """)
        #expect(SwifQL.where(CarBrands.column("name") == "hello" || CarBrands.column("name") == "world").prepare(.duck).splitted.query == """
        WHERE "CarBrands"."name" = $1 OR "CarBrands"."name" = $2
        """)
    }
    
    // MARK: - FormattedKeyPath
    
    @Test("Test Formatted KeyPath")
    func formattedKeyPath() {
        check(
            SwifQL.select(FormattedKeyPath(CarBrands.self, "id")),
            .psql(#"SELECT "CarBrands"."id""#),
            .mysql("SELECT CarBrands.id"),
            .duck(#"SELECT "CarBrands"."id""#)
        )
        check(
            SwifQL.select(CarBrands.mkp("id")),
            .psql(#"SELECT "CarBrands"."id""#),
            .mysql("SELECT CarBrands.id"),
            .duck(#"SELECT "CarBrands"."id""#)
        )
    }
}
