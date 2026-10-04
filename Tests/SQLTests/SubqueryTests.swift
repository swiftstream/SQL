@testable import SQL
import Testing

@Suite("Subquery Tests")
struct SubqueryTests: SwifQLTests {
    // MARK: - SUBQUERY WITH ALIAS
    
    @Test("Test Subquery With Alias")
    func subqueryWithAlias() {
        let a = CarBrands.as("a")
        let b = CarBrands.as("b")
        // WRONG EXAMPLE because of `|` postfix operator near `alias1`
//        let query = SwifQL.select(
//            a~\.name,
//            |SwifQL.select(Fn.jsonAgg(=>"alias1") => "test1" )
//                .from(
//                    |SwifQL.select(b~\.name => "someName")
//                        .from(b.table)
//                        .where(b~\.id == a~\.id)|
//                ) => "alias1"|
//            )
//            .from(a.table)
        // RIGHT EXAMPLE
        // so use subquery inside brackets or even better move it into variable (it'd be more beautiful and easy to support)
        check(
            SwifQL
                .select(
                    a.column("name"),
                    |(SwifQL.select(Fn.jsonAgg(=>"alias1") => "test1")
                        .from(
                            |SwifQL.select(b.column("name") => "someName")
                                .from(b.table)
                                .where(b.column("id") == a.column("id"))|
                        ) => "alias1")|
                )
                .from(a.table),
            .psql(#"SELECT "a"."name", (SELECT json_agg("alias1") as "test1" FROM (SELECT "b"."name" as "someName" FROM "CarBrands" AS "b" WHERE "b"."id" = "a"."id") as "alias1") FROM "CarBrands" AS "a""#),
            .mysql("SELECT a.name, (SELECT json_agg(alias1) as test1 FROM (SELECT b.name as someName FROM CarBrands AS b WHERE b.id = a.id) as alias1) FROM CarBrands AS a")
        )
    }
}
