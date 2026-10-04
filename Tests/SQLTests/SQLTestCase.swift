import Foundation
import Testing
@testable import SQL

protocol SwifQLTests {}
extension SwifQLTests {
    func check(_ query: SwifQLable, _ dialects: QueryWithDialect...) {
        dialects.forEach {
            #expect(query.prepare($0.dialect).plain == $0.plainQuery)
            if let bindedQuery = $0.bindedQuery {
                let prepared = query.prepare($0.dialect)
                let splitted = prepared.splitted
                #expect(splitted.query == bindedQuery)
            }
        }
    }
    
    func check(_ query: SwifQLable, all rawQuery: String) {
        SQLDialect.all.forEach {
            #expect(query.prepare($0).plain == rawQuery)
        }
    }
}

struct DeletedSchema: Schemable {
    static var schemaName: String { "deleted" }
}

enum GearboxType: String, SwifQLEnum {
    case manual, auto, cvt
}

struct SchemableCarBrands: Table, Schemable {
    static var tableName: String { "CarBrands" }
    
    @Column("id")
    var id: UUID
    @Column("name")
    var name: String
    @Column("createdAt")
    var createdAt: Date
    
    init() {}
}

struct CarBrands: Table {
    @Column("id")
    var id: UUID
    @Column("name")
    var name: String
    @Column("createdAt")
    var createdAt: Date
    
    init() {}
}

struct CarBrandReferences: Table {
    @Column("id")
    var id: UUID
    @Column("model")
    var model: String
    @Column("available")
    var available: Bool
    @Column("score")
    var score: Int
    @Column("mainGers")
    var mainGers: GearboxType
    @Column("availableGers")
    var availableGers: [GearboxType]
    @Column("availableYears")
    var availableYears: [Int]
    @Column("knowedIssues")
    var knowedIssues: [UUID]
    @Column("tags")
    var tags: [String]
    
    init() {}
}

var cb: GenericTableAlias<CarBrands> { CarBrands.as("cb") }

struct QueryWithDialect {
    let dialect: SQLDialect
    let plainQuery: String
    let bindedQuery: String?
    
    static func psql(_ plainQuery: String, _ bindedQuery: String? = nil) -> Self {
        .init(dialect: .psql, plainQuery: plainQuery, bindedQuery: bindedQuery)
    }
    
    static func mysql(_ plainQuery: String, _ bindedQuery: String? = nil) -> Self {
        .init(dialect: .mysql, plainQuery: plainQuery, bindedQuery: bindedQuery)
    }

    static func duck(_ plainQuery: String, _ bindedQuery: String? = nil) -> Self {
        .init(dialect: .duck, plainQuery: plainQuery, bindedQuery: bindedQuery)
    }
}
