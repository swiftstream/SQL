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
            .psql(#"FROM "car_brands""#),
            .mysql("FROM car_brands"),
            .duck(#"FROM "car_brands""#)
        )
    }
    
    @Test("Test From Two Tables")
    func fromTwoTables() {
        check(
            SwifQL.from(CarBrands.table, CarBrands.table),
            .psql(#"FROM "car_brands", "car_brands""#),
            .mysql("FROM car_brands, car_brands"),
            .duck(#"FROM "car_brands", "car_brands""#)
        )
    }
    
    @Test("Test From One Table Alias")
    func fromOneTableAlias() {
        check(
            SwifQL.from(cb.table),
            .psql(#"FROM "car_brands" AS "cb""#),
            .mysql("FROM car_brands AS cb"),
            .duck(#"FROM "car_brands" AS "cb""#)
        )
    }
    
    @Test("Test From Two Table Aliases")
    func fromTwoTableAliases() {
        check(
            SwifQL.from(cb.table, cb.table),
            .psql(#"FROM "car_brands" AS "cb", "car_brands" AS "cb""#),
            .mysql("FROM car_brands AS cb, car_brands AS cb"),
            .duck(#"FROM "car_brands" AS "cb", "car_brands" AS "cb""#)
        )
    }
    
    @Test("Test From Table And Table Alias")
    func fromTableAndTableAlias() {
        check(
            SwifQL.from(CarBrands.table, cb.table),
            .psql(#"FROM "car_brands", "car_brands" AS "cb""#),
            .mysql("FROM car_brands, car_brands AS cb"),
            .duck(#"FROM "car_brands", "car_brands" AS "cb""#)
        )
    }
}
