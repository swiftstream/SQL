@testable import SQL
import Testing

@Suite("Case Tests")
struct CaseTests: SwifQLTests {
    // MARK: - Case When Then Else
    
    @Test("Test Case When Then Else 1")
    func caseWhenThenElse1() {
        check(
            Case
                .when(CarBrands.column("name") == "BMW")
            .then("Crazy driver")
                .when(CarBrands.column("name") == "Tesla")
            .then("Fancy driver")
                .else("Normal driver")
            .end,
            .psql(#"CASE WHEN "car_brands"."name" = 'BMW' THEN 'Crazy driver' WHEN "car_brands"."name" = 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"#),
            .mysql("CASE WHEN car_brands.name = 'BMW' THEN 'Crazy driver' WHEN car_brands.name = 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"),
            .duck(#"CASE WHEN "car_brands"."name" = 'BMW' THEN 'Crazy driver' WHEN "car_brands"."name" = 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"#)
        )
    }
    
    @Test("Test Case When Then Else 2")
    func caseWhenThenElse2() {
        check(
            Case(CarBrands.column("name"))
                .when("BMW")
            .then("Crazy driver")
                .when("Tesla")
            .then("Fancy driver")
                .else("Normal driver")
            .end,
            .psql(#"CASE "car_brands"."name" WHEN 'BMW' THEN 'Crazy driver' WHEN 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"#),
            .mysql("CASE car_brands.name WHEN 'BMW' THEN 'Crazy driver' WHEN 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"),
            .duck(#"CASE "car_brands"."name" WHEN 'BMW' THEN 'Crazy driver' WHEN 'Tesla' THEN 'Fancy driver' ELSE 'Normal driver' END"#)
        )
    }
}
