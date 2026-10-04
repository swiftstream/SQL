@testable import SQL
import Testing

@Suite("With Tests")
struct WithTests: SwifQLTests {
    @Test("Test With")
    func with() {
        check(
            SwifQL
                .with(.init(Path.Table("Table1"), SwifQL.select(Path.Table("Table2").*).from(Path.Table("Table2"))))
                .select(Path.Table("Table1").*)
                .from(Path.Table("Table1")),
            .psql(#"WITH "Table1" as (SELECT "Table2".* FROM "Table2") SELECT "Table1".* FROM "Table1""#),
            .mysql("WITH Table1 as (SELECT Table2.* FROM Table2) SELECT Table1.* FROM Table1"),
                .duck(#"WITH "Table1" as (SELECT "Table2".* FROM "Table2") SELECT "Table1".* FROM "Table1""#)
        )
    }
    
    @Test("Test With Columns")
    func withColumns() {
        struct Table1: Table { init() {} }
        check(
            SwifQL
                .with(
                    .init(Table1.table, SwifQL.select(Table1.table.*).from(Table1.table)),
                    .init(Path.Table("Table2"), columns: [Path.Column("hi"), Path.Column("there")], SwifQL.select(Path.Table("Table2").*).from(Path.Table("Table2")))
                )
                .select(Path.Table("Table3").*)
                .from(Path.Table("Table3")),
            .psql(#"WITH "Table1" as (SELECT "Table1".* FROM "Table1"), "Table2" ("hi", "there") as (SELECT "Table2".* FROM "Table2") SELECT "Table3".* FROM "Table3""#),
            .mysql("WITH Table1 as (SELECT Table1.* FROM Table1), Table2 (hi, there) as (SELECT Table2.* FROM Table2) SELECT Table3.* FROM Table3"),
                .duck(#"WITH "Table1" as (SELECT "Table1".* FROM "Table1"), "Table2" ("hi", "there") as (SELECT "Table2".* FROM "Table2") SELECT "Table3".* FROM "Table3""#)
        )
    }
}
