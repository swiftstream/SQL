import Testing
@testable import SwifQL

@Suite("Create Table")
struct CreateTableTests: SwifQLTests {
    @Test("CreateTable renders definitions for every established dialect")
    func createTableDefinitions() {
        let query = CreateTable("users") {
            NewColumn("id", .integer)
            NewColumn("email", .text)
        }

        check(
            query,
            .psql(#"CREATE TABLE "users" ("id" integer, "email" text)"#),
            .mysql("CREATE TABLE users (id integer, email text)"),
            .duck(#"CREATE TABLE "users" ("id" integer, "email" text)"#)
        )
    }

    @Test("CreateTable renders schema-qualified tables")
    func schemaQualifiedTable() {
        let query = CreateTable("users", schema: "auth") {
            NewColumn("id", .integer)
        }

        check(
            query,
            .psql(#"CREATE TABLE "auth"."users" ("id" integer)"#),
            .mysql("CREATE TABLE auth.users (id integer)"),
            .duck(#"CREATE TABLE "auth"."users" ("id" integer)"#)
        )
    }

    @Test("CreateTable includes generated columns")
    func generatedColumn() {
        let query = CreateTable("metrics") {
            NewColumn("base", .integer)
            GeneratedColumn("derived", as: Path.Column("base") + 1)
        }

        check(
            query,
            .psql(#"CREATE TABLE "metrics" ("base" integer, "derived" as ("base" + 1))"#),
            .mysql("CREATE TABLE metrics (base integer, derived as (base + 1))"),
            .duck(#"CREATE TABLE "metrics" ("base" integer, "derived" as ("base" + 1))"#)
        )
    }

    @Test("CreateTable preserves canonical constraints")
    func constraints() {
        let query = CreateTable("users") {
            NewColumn("id", .uuid).primaryKey()
            NewColumn("email", .text).unique().notNull()
        }

        check(
            query,
            .psql(#"CREATE TABLE "users" ("id" uuid PRIMARY KEY, "email" text UNIQUE NOT NULL)"#),
            .mysql("CREATE TABLE users (id uuid PRIMARY KEY, email text UNIQUE NOT NULL)"),
            .duck(#"CREATE TABLE "users" ("id" uuid PRIMARY KEY, "email" text UNIQUE NOT NULL)"#)
        )
    }

    @Test("CreateTable snapshots mutable definitions")
    func snapshotSemantics() {
        let id = NewColumn("id", .integer)
        let query = CreateTable("users") {
            id
        }

        let before = query.prepare(.duck).plain
        id.notNull()
        let after = query.prepare(.duck).plain

        #expect(before == #"CREATE TABLE "users" ("id" integer)"#)
        #expect(after == before)
        #expect(!after.contains("NOT NULL"))
    }

    @Test("CreateTable preserves preparation bindings and has no semicolon")
    func preparationNeutrality() {
        let query = CreateTable("metrics") {
            NewColumn("base", .integer)
            GeneratedColumn("derived", as: Path.Column("base") + 7)
        }

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"CREATE TABLE "metrics" ("base" integer, "derived" as ("base" + 7))"#)
        #expect(prepared.splitted.query == #"CREATE TABLE "metrics" ("base" integer, "derived" as ("base" + $1))"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["7"])
        #expect(!prepared.plain.hasSuffix(";"))
    }
}
