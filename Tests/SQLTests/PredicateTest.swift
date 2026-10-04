@testable import SQL
import Foundation
import Testing

@Suite("Predicate Tests")
struct PredicateTests: SwifQLTests {
    
    // MARK: - Greater Than (Number)
    
    @Test("Test Greater Than")
    func greaterThan() {
        check(
            SwifQL.where(\CarBrandReferences.$score > 10),
            .psql(#"WHERE "CarBrandReferences"."score" > 10"#),
            .mysql("WHERE CarBrandReferences.score > 10"),
            .duck(#"WHERE "CarBrandReferences"."score" > 10"#)
        )
    }
    
    // MARK: - Less Than (Number)
    
    @Test("Test Less Than")
    func lessThan() {
        check(
            SwifQL.where(\CarBrandReferences.$score < 10),
            .psql(#"WHERE "CarBrandReferences"."score" < 10"#),
            .mysql("WHERE CarBrandReferences.score < 10"),
            .duck(#"WHERE "CarBrandReferences"."score" < 10"#)
        )
    }
    
    // MARK: - Greater Than Or Equal (Number)
    
    @Test("Test Greater Than Or Equal")
    func greaterThanOrEqual() {
        check(
            SwifQL.where(\CarBrandReferences.$score >= 10),
            .psql(#"WHERE "CarBrandReferences"."score" >= 10"#),
            .mysql("WHERE CarBrandReferences.score >= 10"),
            .duck(#"WHERE "CarBrandReferences"."score" >= 10"#)
        )
    }
    
    // MARK: - Less Than Or Equal (Number)
    
    @Test("Test Less Than Or Equal")
    func lessThanOrEqual() {
        check(
            SwifQL.where(\CarBrandReferences.$score <= 10),
            .psql(#"WHERE "CarBrandReferences"."score" <= 10"#),
            .mysql("WHERE CarBrandReferences.score <= 10"),
            .duck(#"WHERE "CarBrandReferences"."score" <= 10"#)
        )
    }
    
    // MARK: - Equal (Number)
    
    @Test("Test Equal Number")
    func equalNumber() {
        check(
            SwifQL.where(\CarBrandReferences.$score == 10),
            .psql(#"WHERE "CarBrandReferences"."score" = 10"#),
            .mysql("WHERE CarBrandReferences.score = 10"),
            .duck(#"WHERE "CarBrandReferences"."score" = 10"#)
        )
    }
    
    // MARK: - Equal (String)
    
    @Test("Test Equal String")
    func equalString() {
        check(
            SwifQL.where(\CarBrandReferences.$model == "x001"),
            .psql(#"WHERE "CarBrandReferences"."model" = 'x001'"#),
            .mysql("WHERE CarBrandReferences.model = 'x001'"),
            .duck(#"WHERE "CarBrandReferences"."model" = 'x001'"#)
        )
    }
    
    // MARK: - Equal (Boolean)
    
    @Test("Test Equal Boolean")
    func equalBoolean() {
        check(
            SwifQL.where(\CarBrandReferences.$available == true),
            .psql(#"WHERE "CarBrandReferences"."available" = TRUE"#),
            .mysql("WHERE CarBrandReferences.available = TRUE"),
            .duck(#"WHERE "CarBrandReferences"."available" = TRUE"#)
        )
    }

    // MARK: - Equal (Enum)
    
    @Test("Test Equal A Type")
    func equalAType() {
        check(
            SwifQL.where(\CarBrandReferences.$mainGers == GearboxType.manual),
            .psql(#"WHERE "CarBrandReferences"."mainGers" = 'manual'"#),
            .mysql("WHERE CarBrandReferences.mainGers = 'manual'"),
            .duck(#"WHERE "CarBrandReferences"."mainGers" = 'manual'"#)
        )
    }
    
    // MARK: - Equal (Null)
    
    @Test("Test Equal NULL")
    func equalNULL() {
        check(
            SwifQL.where(\CarBrandReferences.$model == nil),
            .psql(#"WHERE "CarBrandReferences"."model" IS NULL"#),
            .mysql("WHERE CarBrandReferences.model IS NULL"),
            .duck(#"WHERE "CarBrandReferences"."model" IS NULL"#)
        )
    }
    
    // MARK: - Not Equal (Number)
    
    @Test("Test Not Equal Number")
    func notEqualNumber() {
        check(
            SwifQL.where(\CarBrandReferences.$score != 10),
            .psql(#"WHERE "CarBrandReferences"."score" != 10"#),
            .mysql("WHERE CarBrandReferences.score != 10"),
            .duck(#"WHERE "CarBrandReferences"."score" != 10"#)
        )
    }
    
    // MARK: - Not Equal (String)
    
    @Test("Test Not Equal String")
    func notEqualString() {
        check(
            SwifQL.where(\CarBrandReferences.$model != "x001"),
            .psql(#"WHERE "CarBrandReferences"."model" != 'x001'"#),
            .mysql("WHERE CarBrandReferences.model != 'x001'"),
            .duck(#"WHERE "CarBrandReferences"."model" != 'x001'"#)
        )
    }
    
    // MARK: - Not Equal (Boolean)
    
    @Test("Test Not Equal Boolean")
    func notEqualBoolean() {
        check(
            SwifQL.where(\CarBrandReferences.$available != true),
            .psql(#"WHERE "CarBrandReferences"."available" != TRUE"#),
            .mysql("WHERE CarBrandReferences.available != TRUE"),
            .duck(#"WHERE "CarBrandReferences"."available" != TRUE"#)
        )
    }
    
    // MARK: - Not Equal (Enum)

    @Test("Test Not Equal A Type")
    func notEqualAType() {
        check(
            SwifQL.where(\CarBrandReferences.$mainGers != GearboxType.manual),
            .psql(#"WHERE "CarBrandReferences"."mainGers" != 'manual'"#),
            .mysql("WHERE CarBrandReferences.mainGers != 'manual'"),
            .duck(#"WHERE "CarBrandReferences"."mainGers" != 'manual'"#)
        )
    }
    
    // MARK: - Not Equal (Null)
    
    @Test("Test Not Equal NULL")
    func notEqualNULL() {
        check(
            SwifQL.where(\CarBrandReferences.$model != nil),
            .psql(#"WHERE "CarBrandReferences"."model" IS NOT NULL"#),
            .mysql("WHERE CarBrandReferences.model IS NOT NULL"),
            .duck(#"WHERE "CarBrandReferences"."model" IS NOT NULL"#)
        )
    }
    
    // MARK: - Between (Int)
    
    @Test("Test Between Int")
    func betweenInt () {
        check(
            SwifQL.where(\CarBrandReferences.$score <> 5 && 20),
            .psql(#"WHERE "CarBrandReferences"."score" BETWEEN 5 AND 20"#),
            .mysql("WHERE CarBrandReferences.score BETWEEN 5 AND 20"),
            .duck(#"WHERE "CarBrandReferences"."score" BETWEEN 5 AND 20"#)
        )
    }
    
    // MARK: - Between (String)
    
    @Test("Test Between String")
    func betweenString () {
        check(
            SwifQL.where(\CarBrandReferences.$model <> "a" && "t"),
            .psql(#"WHERE "CarBrandReferences"."model" BETWEEN 'a' AND 't'"#),
            .mysql("WHERE CarBrandReferences.model BETWEEN 'a' AND 't'"),
            .duck(#"WHERE "CarBrandReferences"."model" BETWEEN 'a' AND 't'"#)
        )
    }
    
    // MARK: - Range @> ([Enum])
    
    @Test("Test Range Left Enum")
    func rangeLeftEnum() {
        check(
            SwifQL.where(\CarBrandReferences.$availableGers ||> [GearboxType.manual]),
            .psql(#"WHERE "CarBrandReferences"."availableGers" @> '{manual}'"#)
        )
    }
    
    // MARK: - Range <@ ([Enum])
    
    @Test("Test Range Right Enum")
    func rangeRightEnum() {
        check(
            SwifQL.where(\CarBrandReferences.$availableGers <|| [GearboxType.manual]),
            .psql(#"WHERE "CarBrandReferences"."availableGers" <@ '{manual}'"#)
        )
    }
    
    // MARK: - Range @> ([String])
    
    @Test("Test Range Left String")
    func rangeLeftString() {
        check(
            SwifQL.where(\CarBrandReferences.$tags ||> PgArray(["red"])),
            .psql(#"WHERE "CarBrandReferences"."tags" @> ARRAY['red']"#)
        )
    }
    
    // MARK: - Range <@ ([String])
    
    @Test("Test Range Right String")
    func rangeRightString() {
        check(
            SwifQL.where(\CarBrandReferences.$tags <|| PgArray(["red"])),
            .psql(#"WHERE "CarBrandReferences"."tags" <@ ARRAY['red']"#)
        )
    }
    
    // MARK: - Range @> ([Int])
    
    @Test("Test Range Left Int")
    func rangeLeftInt() {
        check(
            SwifQL.where(\CarBrandReferences.$availableYears ||> PgArray([1, 2, 3])),
            .psql(#"WHERE "CarBrandReferences"."availableYears" @> ARRAY[1, 2, 3]"#)
        )
    }
    
    // MARK: - Range <@ ([Int])
    
    @Test("Test Range Right Int")
    func rangeRightInt() {
        check(
            SwifQL.where(\CarBrandReferences.$availableYears <|| PgArray([1, 2, 3])),
            .psql(#"WHERE "CarBrandReferences"."availableYears" <@ ARRAY[1, 2, 3]"#)
        )
    }
    
    // MARK: - Range @> ([UUID])
    
    @Test("Test Range Left UUID")
    func rangeLeftUUID() {
        check(
            SwifQL.where(\CarBrandReferences.$knowedIssues ||> PgArray([UUID(uuidString: "25afebec-179e-43ff-8c7b-a0a460c7c996")!, UUID(uuidString: "25afebec-179e-43ff-8c7b-a0a460c7c996")!])),
            .psql(#"WHERE "CarBrandReferences"."knowedIssues" @> ARRAY['25AFEBEC-179E-43FF-8C7B-A0A460C7C996', '25AFEBEC-179E-43FF-8C7B-A0A460C7C996']"#)
        )
    }
    
    // MARK: - Range <@ ([UUID])
    
    @Test("Test Range Right UUID")
    func rangeRightUUID() {
        check(
            SwifQL.where(\CarBrandReferences.$knowedIssues <|| PgArray([UUID(uuidString: "25afebec-179e-43ff-8c7b-a0a460c7c996")!, UUID(uuidString: "25afebec-179e-43ff-8c7b-a0a460c7c996")!])),
            .psql(#"WHERE "CarBrandReferences"."knowedIssues" <@ ARRAY['25AFEBEC-179E-43FF-8C7B-A0A460C7C996', '25AFEBEC-179E-43FF-8C7B-A0A460C7C996']"#)
        )
    }
}
