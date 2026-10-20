@testable import SQL
import Testing

@Suite("Order Tests")
struct OrderTests: SwifQLTests {
    // MARK: - Order by simple
    
    @Test("Test Order By Simple")
    func orderBySimple() {
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name")), .desc(CarBrands.column("id"))),
            .psql(#"ORDER BY "car_brands"."name" ASC, "car_brands"."id" DESC"#),
            .mysql("ORDER BY car_brands.name ASC, car_brands.id DESC"),
            .duck(#"ORDER BY "car_brands"."name" ASC, "car_brands"."id" DESC"#)
        )
    }
    
    // MARK: - Order by with nulls
    
    @Test("Test Order By With Nulls")
    func orderByWithNulls() {
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name"), nulls: .first), .desc(CarBrands.column("id"), nulls: .last)),
            .psql(#"ORDER BY "car_brands"."name" ASC NULLS FIRST, "car_brands"."id" DESC NULLS LAST"#),
            .duck(#"ORDER BY "car_brands"."name" ASC NULLS FIRST, "car_brands"."id" DESC NULLS LAST"#)
        )
        check(
            SwifQL.orderBy(.asc(CarBrands.column("name") == nil, CarBrands.column("name")), .desc(CarBrands.column("id") != nil, CarBrands.column("id"))),
            .mysql("ORDER BY car_brands.name IS NULL, car_brands.name ASC, car_brands.id IS NOT NULL, car_brands.id DESC")
        )
    }
    
    // MARK: - Order by with direction
    
    @Test("Test Order By Direction")
    func orderByDirection() {
        check(
            SwifQL.orderBy(.direction(.asc, CarBrands.column("name"), nulls: .last)),
            .psql(#"ORDER BY "car_brands"."name" ASC NULLS LAST"#),
            .duck(#"ORDER BY "car_brands"."name" ASC NULLS LAST"#)
        )
        check(
            SwifQL.orderBy(.direction(.desc, CarBrands.column("id"), nulls: .first)),
            .mysql("ORDER BY car_brands.id DESC NULLS FIRST")
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
