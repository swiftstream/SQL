import Testing
@testable import SQL

@Suite("Alter Table")
struct AlterTableTests: SwifQLTests {
    @Test("AddColumn renders its direct action value")
    func addColumn() {
        let action = AddColumn("display_name", .text)

        check(
            action,
            .psql(#"ADD COLUMN "display_name" text"#),
            .mysql("ADD COLUMN display_name text"),
            .duck(#"ADD COLUMN "display_name" text"#)
        )
        #expect(action.prepare(.duck).splitted.values.isEmpty)
        #expect(!action.prepare(.duck).plain.hasSuffix(";"))
    }

    @Test("AlterTable renders one action across every established dialect")
    func alterTableOneAction() {
        let query = AlterTable("users") {
            AddColumn("display_name", .text)
        }

        check(
            query,
            .psql(#"ALTER TABLE "users" ADD COLUMN "display_name" text"#),
            .mysql("ALTER TABLE users ADD COLUMN display_name text"),
            .duck(#"ALTER TABLE "users" ADD COLUMN "display_name" text"#)
        )
        #expect(query.prepare(.duck).splitted.values.isEmpty)
        #expect(!query.prepare(.duck).plain.hasSuffix(";"))
    }

    @Test("AlterTable renders schema-qualified one-action statements")
    func alterTableSchema() {
        let query = AlterTable("users", schema: "auth") {
            AddColumn("display_name", .text)
        }

        check(
            query,
            .psql(#"ALTER TABLE "auth"."users" ADD COLUMN "display_name" text"#),
            .mysql("ALTER TABLE auth.users ADD COLUMN display_name text"),
            .duck(#"ALTER TABLE "auth"."users" ADD COLUMN "display_name" text"#)
        )
    }

    @Test("AlterTable preserves action order in one statement")
    func alterTableMultipleActions() {
        let query = AlterTable("users") {
            AddColumn("a", .integer)
            AddColumn("b", .text)
        }

        check(
            query,
            .psql(#"ALTER TABLE "users" ADD COLUMN "a" integer, ADD COLUMN "b" text"#),
            .mysql("ALTER TABLE users ADD COLUMN a integer, ADD COLUMN b text"),
            .duck(#"ALTER TABLE "users" ADD COLUMN "a" integer, ADD COLUMN "b" text"#)
        )
        #expect(query.prepare(.duck).splitted.values.isEmpty)
        #expect(!query.prepare(.duck).plain.hasSuffix(";"))
    }
}
