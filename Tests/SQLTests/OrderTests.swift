@testable import SQL
import Testing

@Suite("Order Tests")
struct OrderTests: SwifQLTests {
    // MARK: - Order by simple
    
    @Test("Test Order By Simple")
    func orderBySimple() {
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name")), .desc(CarBrands.column("id"))),
            .psql(#"ORDER BY "CarBrands"."name" ASC, "CarBrands"."id" DESC"#),
            .mysql("ORDER BY CarBrands.name ASC, CarBrands.id DESC"),
            .duck(#"ORDER BY "CarBrands"."name" ASC, "CarBrands"."id" DESC"#)
        )
    }
    
    // MARK: - Order by with nulls
    
    @Test("Test Order By With Nulls")
    func orderByWithNulls() {
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name"), nulls: .first), .desc(CarBrands.column("id"), nulls: .last)),
            .psql(#"ORDER BY "CarBrands"."name" ASC NULLS FIRST, "CarBrands"."id" DESC NULLS LAST"#),
            .duck(#"ORDER BY "CarBrands"."name" ASC NULLS FIRST, "CarBrands"."id" DESC NULLS LAST"#)
        )
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name") == nil, CarBrands.column("name")), .desc(CarBrands.column("id") != nil, CarBrands.column("id"))),
            .mysql("ORDER BY CarBrands.name IS NULL, CarBrands.name ASC, CarBrands.id IS NOT NULL, CarBrands.id DESC")
        )
    }
    
    // MARK: - Order by with direction
    
    @Test("Test Order By Direction")
    func orderByDirection() {
        check(
            SwifQL.orderBy(.direction(.asc, CarBrands.column("name"), nulls: .last)),
            .psql(#"ORDER BY "CarBrands"."name" ASC NULLS LAST"#),
            .duck(#"ORDER BY "CarBrands"."name" ASC NULLS LAST"#)
        )
        check(
            SwifQL.orderBy(.direction(.desc, CarBrands.column("id"), nulls: .first)),
            .mysql("ORDER BY CarBrands.id DESC NULLS FIRST")
        )
    }
    
    // MARK: - Order by random() / Order by rand()
    
    @Test("Test Order By Random")
    func orderByRandom() {
        check(
            SwifQL.orderBy(.random),
            .psql(#"ORDER BY random()"#),
            .duck(#"ORDER BY random()"#)
        )
        check(
            SwifQL.orderBy(.random),
            .mysql("ORDER BY rand()")
        )
    }
}
