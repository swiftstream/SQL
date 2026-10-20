@testable import SQL
import Testing

@Suite("Directive Tests")
struct DirectiveTests: SwifQLTests {
    // MARK: - UPDATE
    
    @Test("Test Update")
    func update() {
        check(
            SwifQL.update(DB.Table("ttt")),
            .psql(#"UPDATE "ttt""#),
            .mysql("UPDATE ttt"),
            .duck(#"UPDATE "ttt""#)
        )
        check(
            SwifQL.update(DB.Schema("sss").table("ttt")),
            .psql(#"UPDATE "sss"."ttt""#),
            .mysql("UPDATE sss.ttt"),
            .duck(#"UPDATE "sss"."ttt""#)
        )
    }
    
    // MARK: - INSERT INTO
    
    @Test("Test Insert Into")
    func insertInto() {
        check(
            SwifQL.insertInto(DB.Table("ttt"), fields: "id"),
            .psql(#"INSERT INTO "ttt" ("id")"#),
            .mysql("INSERT INTO ttt (id)"),
            .duck(#"INSERT INTO "ttt" ("id")"#)
        )
        check(
            SwifQL.insertInto(DB.Schema("sss").table("ttt"), fields: "id"),
            .psql(#"INSERT INTO "sss"."ttt" ("id")"#),
            .mysql("INSERT INTO sss.ttt (id)"),
            .duck(#"INSERT INTO "sss"."ttt" ("id")"#)
        )
        check(
            SwifQL.insertInto(CarBrands.table, fields: CarBrands.column("id")),
            .psql(#"INSERT INTO "car_brands" ("id")"#),
            .mysql("INSERT INTO car_brands (id)"),
            .duck(#"INSERT INTO "car_brands" ("id")"#)
        )
        check(
            SwifQL.insertInto(CarBrands.table, fields: CarBrands.column("id"), CarBrands.column("name"), CarBrands.column("createdAt")),
            .psql(#"INSERT INTO "car_brands" ("id", "name", "createdAt")"#),
            .mysql("INSERT INTO car_brands (id, name, createdAt)"),
            .duck(#"INSERT INTO "car_brands" ("id", "name", "createdAt")"#)
        )
        check(
            SwifQL.insertInto(cb.table, fields: cb.column("id")),
            .psql(#"INSERT INTO "car_brands" AS "cb" ("id")"#),
            .mysql("INSERT INTO car_brands AS cb (id)"),
            .duck(#"INSERT INTO "car_brands" AS "cb" ("id")"#)
        )
        check(
            SwifQL.insertInto(cb.table, fields: cb.column("id"), cb.column("name"), cb.column("createdAt")),
            .psql(#"INSERT INTO "car_brands" AS "cb" ("id", "name", "createdAt")"#),
            .mysql("INSERT INTO car_brands AS cb (id, name, createdAt)"),
            .duck(#"INSERT INTO "car_brands" AS "cb" ("id", "name", "createdAt")"#)
        )
        check(
            SwifQL.insertInto(cb.table, fields: CarBrands.column("id"), cb.column("name"), CarBrands.column("createdAt")),
            .psql(#"INSERT INTO "car_brands" AS "cb" ("id", "name", "createdAt")"#),
            .mysql("INSERT INTO car_brands AS cb (id, name, createdAt)"),
            .duck(#"INSERT INTO "car_brands" AS "cb" ("id", "name", "createdAt")"#)
        )
    }
    
    // MARK: - Delete
    
    @Test("Test Delete")
    func delete() {
        check(
            SwifQL.delete(from: CarBrands.table).where(CarBrands.column("name") == "BMW"),
            .psql(#"DELETE FROM "car_brands" WHERE "car_brands"."name" = 'BMW'"#),
            .mysql("DELETE FROM car_brands WHERE car_brands.name = 'BMW'"),
            .duck(#"DELETE FROM "car_brands" WHERE "car_brands"."name" = 'BMW'"#)
        )
    }
    
    // MARK: - RETURNING
    
    @Test("Test Returning")
    func returning() {
        check(
            SwifQL.returning("hello_world", "bye_world"),
            .psql(#"RETURNING "hello_world", "bye_world""#),
            .mysql("RETURNING hello_world, bye_world"),
            .duck(#"RETURNING "hello_world", "bye_world""#)
        )
        check(
            SwifQL.returning(CarBrands.column("id"), CarBrands.column("name")),
            .psql(#"RETURNING "id", "name""#),
            .mysql("RETURNING id, name"),
            .duck(#"RETURNING "id", "name""#)
        )
    }
    
    // MARK: - ON CONFLICT DO NOTHING
    
    @Test("Test On Conflict")
    func onConflict() {
        check(
            SwifQL.on.conflict(CarBrands.column("id"), CarBrands.column("name")),
            .psql(#"ON CONFLICT ("id", "name")"#),
            .mysql("ON CONFLICT (id, name)")
        )
        check(
            SwifQL.on.conflict(CarBrands.column("id"), CarBrands.column("name")).do.nothing,
            .psql(#"ON CONFLICT ("id", "name") DO NOTHING"#),
            .mysql("ON CONFLICT (id, name) DO NOTHING")
        )
    }
    
    // MARK: - ON CONFLICT ON CONSTRAINT DO NOTHING
    
    @Test("Test On Conflict On Constraint Do Nothing")
    func onConflictOnConstraintDoNothing() {
        check(
            SwifQL.on.conflict.on.constraint("hello_world"),
            .psql(#"ON CONFLICT ON CONSTRAINT "hello_world""#),
            .mysql("ON CONFLICT ON CONSTRAINT hello_world")
        )
        check(
            SwifQL.on.conflict.on.constraint("hello_world").do.nothing,
            .psql(#"ON CONFLICT ON CONSTRAINT "hello_world" DO NOTHING"#),
            .mysql("ON CONFLICT ON CONSTRAINT hello_world DO NOTHING")
        )
        check(
            SwifQL.on.conflict.on.constraint(CarBrands.column("name")),
            .psql(#"ON CONFLICT ON CONSTRAINT "name""#),
            .mysql("ON CONFLICT ON CONSTRAINT name")
        )
    }
    
    // MARK: - DO NOTHING
    
    @Test("Test Do Nothing")
    func doNothing() {
        check(
            SwifQL.do.nothing,
            .psql("DO NOTHING"),
            .mysql("DO NOTHING"),
            .duck("DO NOTHING")
        )
    }
    
    // MARK: - NOT / NOT BETWEEN / BETWEEN
    
    @Test("Test Not And Between")
    func notAndBetween() {
        check(
            SwifQL.between(10.and(20)),
            .psql("BETWEEN 10 AND 20"),
            .mysql("BETWEEN 10 AND 20"),
            .duck("BETWEEN 10 AND 20")
        )
        check(
            SwifQL.not(SwifQL.between(10.and(20))),
            .psql("NOT BETWEEN 10 AND 20"),
            .mysql("NOT BETWEEN 10 AND 20"),
            .duck("NOT BETWEEN 10 AND 20")
        )
        check(
            SwifQL.between((CarBrands.column("id")).and(CarBrands.column("name"))),
            .psql(#"BETWEEN "car_brands"."id" AND "car_brands"."name""#),
            .mysql("BETWEEN car_brands.id AND car_brands.name"),
            .duck(#"BETWEEN "car_brands"."id" AND "car_brands"."name""#)
        )
        check(
            SwifQL.not(SwifQL.between((CarBrands.column("id")).and(CarBrands.column("name")))),
            .psql(#"NOT BETWEEN "car_brands"."id" AND "car_brands"."name""#),
            .mysql("NOT BETWEEN car_brands.id AND car_brands.name"),
            .duck(#"NOT BETWEEN "car_brands"."id" AND "car_brands"."name""#)
        )
    }
}
