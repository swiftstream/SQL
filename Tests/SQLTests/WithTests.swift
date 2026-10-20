@testable import SQL
import Testing

@Suite("With Tests")
struct WithTests: SwifQLTests {
    @Test("Test With")
    func with() {
        check(
            SwifQL
                .with(.init(DB.Table("Table1"), SwifQL.select(DB.Table("Table2").*).from(DB.Table("Table2"))))
                .select(DB.Table("Table1").*)
                .from(DB.Table("Table1")),
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
                    .init(DB.Table("Table2"), columns: [DB.Column("hi"), DB.Column("there")], SwifQL.select(DB.Table("Table2").*).from(DB.Table("Table2")))
                )
                .select(DB.Table("Table3").*)
                .from(DB.Table("Table3")),
            .psql(#"WITH "table1" as (SELECT "table1".* FROM "table1"), "Table2" ("hi", "there") as (SELECT "Table2".* FROM "Table2") SELECT "Table3".* FROM "Table3""#),
            .mysql("WITH table1 as (SELECT table1.* FROM table1), Table2 (hi, there) as (SELECT Table2.* FROM Table2) SELECT Table3.* FROM Table3"),
                .duck(#"WITH "table1" as (SELECT "table1".* FROM "table1"), "Table2" ("hi", "there") as (SELECT "Table2".* FROM "Table2") SELECT "Table3".* FROM "Table3""#)
        )
    }
}
