@testable import SQL
import Testing

@Suite("From Tests")
struct FromTests: SwifQLTests {
    //MARK: - FROM
    
    @Test("Test Select From")
    func selectFrom() {
        check(
            SwifQL.select(1).from(),
            .psql("SELECT 1 FROM "),
            .mysql("SELECT 1 FROM ")
        )
    }
    
    @Test("Test From")
    func from() {
        check(
            SwifQL.from(),
            .psql("FROM "),
            .mysql("FROM ")
        )
    }
    
    @Test("Test From One Table")
    func fromOneTable() {
        check(
            SwifQL.from(CarBrands.table),
            .psql(#"FROM "CarBrands""#),
            .mysql("FROM CarBrands"),
            .duck(#"FROM "CarBrands""#)
        )
    }
    
    @Test("Test From Two Tables")
    func fromTwoTables() {
        check(
            SwifQL.from(CarBrands.table, CarBrands.table),
            .psql(#"FROM "CarBrands", "CarBrands""#),
            .mysql("FROM CarBrands, CarBrands"),
            .duck(#"FROM "CarBrands", "CarBrands""#)
        )
    }
    
    @Test("Test From One Table Alias")
    func fromOneTableAlias() {
        check(
            SwifQL.from(cb.table),
            .psql(#"FROM "CarBrands" AS "cb""#),
            .mysql("FROM CarBrands AS cb"),
            .duck(#"FROM "CarBrands" AS "cb""#)
        )
    }
    
    @Test("Test From Two Table Aliases")
    func fromTwoTableAliases() {
        check(
            SwifQL.from(cb.table, cb.table),
            .psql(#"FROM "CarBrands" AS "cb", "CarBrands" AS "cb""#),
            .mysql("FROM CarBrands AS cb, CarBrands AS cb"),
            .duck(#"FROM "CarBrands" AS "cb", "CarBrands" AS "cb""#)
        )
    }
    
    @Test("Test From Table And Table Alias")
    func fromTableAndTableAlias() {
        check(
            SwifQL.from(CarBrands.table, cb.table),
            .psql(#"FROM "CarBrands", "CarBrands" AS "cb""#),
            .mysql("FROM CarBrands, CarBrands AS cb"),
            .duck(#"FROM "CarBrands", "CarBrands" AS "cb""#)
        )
    }
}
