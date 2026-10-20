@testable import SQL
import Testing
import Foundation

@Suite("Select Tests")
struct SelectTests: SwifQLTests {
    @Test("Test Select")
    func select() {
        check(SwifQL.select, all: "SELECT")
        check(SwifQL.select(), all: "SELECT ")
    }
    
    @Test("Test Select String")
    func selectString() {
        check(
            SwifQL.select("hello"),
            .psql("SELECT 'hello'"),
            .mysql("SELECT 'hello'"),
            .duck("SELECT 'hello'")
        )
    }
    
//    @Test("Test Select UUID Array")
//    func selectUUIDArray() {
//        check(
//            SwifQL ||> [PostgresArray(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))],
//            .psql("SELECT 'hello'"),
//            .mysql("SELECT 'hello'")
//        )
//    }
    
    @Test("Test Select Int")
    func selectInt() {
        check(
            SwifQL.select(1),
            .psql("SELECT 1"),
            .mysql("SELECT 1"),
            .duck("SELECT 1")
        )
    }
    
    @Test("Test Select Double")
    func selectDouble() {
        check(
            SwifQL.select(1.234),
            .psql("SELECT 1.234"),
            .mysql("SELECT 1.234"),
            .duck("SELECT 1.234")
        )
    }

    @Test("Test Select Date")
    func selectData() {
        let base64 = "Aa+/0w=="
        let data = Data(base64Encoded: base64)!
        check(
            SwifQL.select(data),
            .psql("SELECT decode('\(base64)', 'base64')")
        )
    }
    
    @Test("Test Select Several Simple Values")
    func selectSeveralSimpleValues() {
        check(
            SwifQL.select("hello", 1, 1.234),
            .psql("SELECT 'hello', 1, 1.234"),
            .mysql("SELECT 'hello', 1, 1.234"),
            .duck("SELECT 'hello', 1, 1.234")
        )
    }
    
    @Test("Test Select Column Path")
    func selectColumn_path() {
        check(
            SwifQL.select(DB.Column("id")),
            .psql(#"SELECT "id""#),
            .mysql("SELECT id"),
            .duck(#"SELECT "id""#)
        )
    }
    
    @Test("Test Select Column KeyPath")
    func selectColumn_keyPath() {
        check(
            SwifQL.select(\CarBrands.$id),
            .psql(#"SELECT "car_brands"."id""#),
            .mysql("SELECT car_brands.id"),
            .duck(#"SELECT "car_brands"."id""#)
        )
    }
    
    @Test("Test Select Column KeyPath Alias Simple")
    func selectColumn_keyPath_alias_simple() {
        check(
            SwifQL.select(\CarBrands.$id => "ident"),
            .psql(#"SELECT "car_brands"."id" as "ident""#),
            .mysql("SELECT car_brands.id as ident"),
            .duck(#"SELECT "car_brands"."id" as "ident""#)
        )
    }
    
    @Test("Test Select Column KeyPath Alias KeyPath")
    func selectColumn_keyPath_alias_keyPath() {
        struct Result: Aliasable {
            @Alias("ident") var abc: UUID
            init () {}
        }
        check(
            SwifQL.select(\CarBrands.$id => \Result.$abc),
            .psql(#"SELECT "car_brands"."id" as "ident""#),
            .mysql("SELECT car_brands.id as ident"),
            .duck(#"SELECT "car_brands"."id" as "ident""#)
        )
    }
    
    @Test("Test Select Column With Table")
    func selectColumnWithTable() {
        check(
            SwifQL.select(DB.Table("CarBrands").column("id")),
            .psql(#"SELECT "CarBrands"."id""#),
            .mysql("SELECT CarBrands.id"),
            .duck(#"SELECT "CarBrands"."id""#)
        )
    }
    
    @Test("Test Select Column With Table And Schema")
    func selectColumnWithTableAndSchema() {
        check(
            SwifQL.select(DB.Schema("test").table("CarBrands").column("id")),
            .psql(#"SELECT "test"."CarBrands"."id""#),
            .mysql("SELECT test.CarBrands.id"),
            .duck(#"SELECT "test"."CarBrands"."id""#)
        )
    }
    
    @Test("Test Select Column Without Table")
    func selectColumnWithoutTable() {
        check(
            SwifQL.select(DB.Column("id")),
            .psql(#"SELECT "id""#),
            .mysql("SELECT id"),
            .duck(#"SELECT "id""#)
        )
    }
    
    @Test("Test Generic Selector All")
    func genericSelector_all() {
        check(
            CarBrands.select,
            .psql(#"SELECT "car_brands".* FROM "car_brands""#),
            .mysql("SELECT car_brands.* FROM car_brands"),
            .duck(#"SELECT "car_brands".* FROM "car_brands""#)
        )
    }
    
    @Test("Select CarBrands")
    func selectCarBrands() {
        check(
            SwifQL.select(CarBrands.column("id")),
            .psql(#"SELECT "car_brands"."id""#),
            .mysql("SELECT car_brands.id"),
            .duck(#"SELECT "car_brands"."id""#)
        )
    }
    
    @Test("Select Schemable CarBrands")
    func selectSchemableCarBrands() {
        check(
            SwifQL.select(SchemableCarBrands.column("id")),
            .psql(#"SELECT "public"."CarBrands"."id""#),
            .mysql("SELECT public.CarBrands.id"),
            .duck(#"SELECT "public"."CarBrands"."id""#)
        )
    }
    
    @Test("Select CarBrands in Customer Schema")
    func selectCarBrandsInCustomSchema() {
        let cb = Schema<CarBrands>("hello")
        check(
            SwifQL.select(cb.column("id")),
            .psql(#"SELECT "hello"."car_brands"."id""#),
            .mysql("SELECT hello.car_brands.id"),
            .duck(#"SELECT "hello"."car_brands"."id""#)
        )
    }
    
    @Test("Select CarBrands Several Fields")
    func selectCarBrandsSeveralFields() {
        check(
            SwifQL.select(CarBrands.column("id"), CarBrands.column("name")),
            .psql(#"SELECT "car_brands"."id", "car_brands"."name""#),
            .mysql("SELECT car_brands.id, car_brands.name"),
            .duck(#"SELECT "car_brands"."id", "car_brands"."name""#)
        )
    }
    
    @Test("Select CarBrands With Alias")
    func selectCarBrandsWithAlias() {
        check(
            SwifQL.select(cb.column("id")),
            .psql(#"SELECT "cb"."id""#),
            .mysql("SELECT cb.id"),
            .duck(#"SELECT "cb"."id""#)
        )
    }
    
    @Test("Select CarBrands With Alias Several Fields")
    func selectCarBrandsWithAliasSeveralFields() {
        check(
            SwifQL.select(cb.column("id"), cb.column("name")),
            .psql(#"SELECT "cb"."id", "cb"."name""#),
            .mysql("SELECT cb.id, cb.name"),
            .duck(#"SELECT "cb"."id", "cb"."name""#)
        )
    }
    
    @Test("Select CarBrands Several Fields Mixed")
    func selectCarBrandsSeveralFieldsMixed() {
        check(
            SwifQL.select(CarBrands.column("id"), cb.column("name"), CarBrands.column("createdAt")),
            .psql(#"SELECT "car_brands"."id", "cb"."name", "car_brands"."createdAt""#),
            .mysql("SELECT car_brands.id, cb.name, car_brands.createdAt"),
            .duck(#"SELECT "car_brands"."id", "cb"."name", "car_brands"."createdAt""#)
        )
    }
    
    //MARK: PostgreSQL Functions
    
    @Test("Select abs")
    func selectFnAbs() {
        check(
            SwifQL.select(Fn.abs(1)),
            .psql("SELECT abs(1)"),
            .mysql("SELECT abs(1)"),
            .duck("SELECT abs(1)")
        )
    }
    
    @Test("Select avg")
    func selectFnAvg() {
        check(
            SwifQL.select(Fn.avg(1)),
            .psql("SELECT avg(1)"),
            .mysql("SELECT avg(1)"),
            .duck("SELECT avg(1)")
        )
    }
    
    @Test("Select bitLength")
    func selectFnBitLength() {
        check(
            SwifQL.select(Fn.bitLength("hello")),
            .psql("SELECT bit_length('hello')"),
            .mysql("SELECT bit_length('hello')"),
            .duck("SELECT bit_length('hello')")
        )
    }
    
    @Test("Select bTrim")
    func selectFnBTrim() {
        check(
            SwifQL.select(Fn.bTrim("hello", "ll")),
            .psql("SELECT btrim('hello', 'll')"),
            .mysql("SELECT btrim('hello', 'll')")
        )
    }
    
    @Test("Select ceil")
    func selectFnCeil() {
        check(
            SwifQL.select(Fn.ceil(1.5)),
            .psql("SELECT ceil(1.5)"),
            .mysql("SELECT ceil(1.5)"),
            .duck("SELECT ceil(1.5)")
        )
    }
    
    @Test("Select ceiling")
    func selectFnCeiling() {
        check(
            SwifQL.select(Fn.ceiling(1.5)),
            .psql("SELECT ceiling(1.5)"),
            .mysql("SELECT ceiling(1.5)"),
            .duck("SELECT ceiling(1.5)")
        )
    }
    
    @Test("Select charLength")
    func selectFnCharLength() {
        check(
            SwifQL.select(Fn.charLength("hello")),
            .psql("SELECT char_length('hello')"),
            .mysql("SELECT char_length('hello')"),
            .duck("SELECT char_length('hello')")
        )
    }
    
    @Test("Select characterLength")
    func selectFnCharacterLength() {
        check(
            SwifQL.select(Fn.characterLength("hello")),
            .psql("SELECT character_length('hello')"),
            .mysql("SELECT character_length('hello')"),
            .duck("SELECT character_length('hello')")
        )
    }
    
    @Test("Select initCap")
    func selectFnInitCap() {
        check(
            SwifQL.select(Fn.initCap("hello")),
            .psql("SELECT initcap('hello')"),
            .mysql("SELECT initcap('hello')")
        )
    }
    
    @Test("Select length")
    func selectFnLength() {
        check(
            SwifQL.select(Fn.length("hello")),
            .psql("SELECT length('hello')"),
            .mysql("SELECT length('hello')"),
            .duck("SELECT length('hello')")
        )
    }
    
    @Test("Select lower")
    func selectFnLower() {
        check(
            SwifQL.select(Fn.lower("hello")),
            .psql("SELECT lower('hello')"),
            .mysql("SELECT lower('hello')"),
            .duck("SELECT lower('hello')")
        )
    }
    
    @Test("Select lPad")
    func selectFnLPad() {
        check(
            SwifQL.select(Fn.lPad("hello", 3, "lo")),
            .psql("SELECT lpad('hello', 3, 'lo')"),
            .mysql("SELECT lpad('hello', 3, 'lo')"),
            .duck("SELECT lpad('hello', 3, 'lo')")
        )
    }
    
    @Test("Select lTrim")
    func selectFnLtrim() {
        check(
            SwifQL.select(Fn.lTrim("hello", "he")),
            .psql("SELECT ltrim('hello', 'he')"),
            .mysql("SELECT ltrim('hello', 'he')"),
            .duck("SELECT ltrim('hello', 'he')")
        )
    }
    
    @Test("Select position")
    func selectFnPosition() {
        check(
            SwifQL.select(Fn.position("el", in: "hello")),
            .psql("SELECT position('el' IN 'hello')"),
            .mysql("SELECT position('el' IN 'hello')"),
            .duck("SELECT position('el' IN 'hello')")
        )
    }
    
    @Test("Select repeat")
    func selectFnRepeat() {
        check(
            SwifQL.select(Fn.repeat("hello", 2)),
            .psql("SELECT repeat('hello', 2)"),
            .mysql("SELECT repeat('hello', 2)"),
            .duck("SELECT repeat('hello', 2)")
        )
    }
    
    @Test("Select replace")
    func selectFnReplace() {
        check(
            SwifQL.select(Fn.replace("hello", "el", "ol")),
            .psql("SELECT replace('hello', 'el', 'ol')"),
            .mysql("SELECT replace('hello', 'el', 'ol')"),
            .duck("SELECT replace('hello', 'el', 'ol')")
        )
    }
    
    @Test("Select rPad")
    func selectFnRPad() {
        check(
            SwifQL.select(Fn.rPad("hello", 2, "ho")),
            .psql("SELECT rpad('hello', 2, 'ho')"),
            .mysql("SELECT rpad('hello', 2, 'ho')"),
            .duck("SELECT rpad('hello', 2, 'ho')")
        )
    }
    
    @Test("Select rTrim")
    func selectFnRTrim() {
        check(
            SwifQL.select(Fn.rTrim(" hello ", " ")),
            .psql("SELECT rtrim(' hello ', ' ')"),
            .mysql("SELECT rtrim(' hello ', ' ')"),
            .duck("SELECT rtrim(' hello ', ' ')")
        )
    }
    
    @Test("Select strPos")
    func selectFnStrPos() {
        check(
            SwifQL.select(Fn.strPos("hello", "ll")),
            .psql("SELECT strpos('hello', 'll')"),
            .mysql("SELECT strpos('hello', 'll')"),
            .duck("SELECT strpos('hello', 'll')")
        )
    }
    
    @Test("Select substring")
    func selectFnSubstring() {
        check(
            SwifQL.select(Fn.substring("hello", from: 1)),
            .psql("SELECT substring('hello' FROM 1)"),
            .mysql("SELECT substring('hello' FROM 1)"),
            .duck("SELECT substring('hello' FROM 1)")
        )
        check(
            SwifQL.select(Fn.substring("hello", for: 4)),
            .psql("SELECT substring('hello' FOR 4)"),
            .mysql("SELECT substring('hello' FOR 4)"),
            .duck("SELECT substring('hello' FOR 4)")
        )
        check(
            SwifQL.select(Fn.substring("hello", from: 1, for: 4)),
            .psql("SELECT substring('hello' FROM 1 FOR 4)"),
            .mysql("SELECT substring('hello' FROM 1 FOR 4)"),
            .duck("SELECT substring('hello' FROM 1 FOR 4)")
        )
    }
    
    @Test("Select translate")
    func selectFnTranslate() {
        check(
            SwifQL.select(Fn.translate("hola", "hola", "hello")),
            .psql("SELECT translate('hola', 'hola', 'hello')"),
            .mysql("SELECT translate('hola', 'hola', 'hello')"),
            .duck("SELECT translate('hola', 'hola', 'hello')")
        )
    }
    
    @Test("Select lTrim")
    func selectFnLTrim() {
        check(
            SwifQL.select(Fn.lTrim("hello", "he")),
            .psql("SELECT ltrim('hello', 'he')"),
            .mysql("SELECT ltrim('hello', 'he')"),
            .duck("SELECT ltrim('hello', 'he')")
        )
    }
    
    @Test("Select upper")
    func selectFnUpper() {
        check(
            SwifQL.select(Fn.upper("hello")),
            .psql("SELECT upper('hello')"),
            .mysql("SELECT upper('hello')"),
            .duck("SELECT upper('hello')")
        )
    }
    
    @Test("Select count")
    func selectFnCount() {
        check(
            SwifQL.select(Fn.count()),
            all: "SELECT count(*)"
        )
        check(
            SwifQL.select(Fn.count(CarBrands.column("id"))),
            .psql(#"SELECT count("car_brands"."id")"#),
            .mysql("SELECT count(car_brands.id)"),
            .duck(#"SELECT count("car_brands"."id")"#)
        )
        check(
            SwifQL.select(Fn.count(cb.column("id"))),
            .psql(#"SELECT count("cb"."id")"#),
            .mysql("SELECT count(cb.id)"),
            .duck(#"SELECT count("cb"."id")"#)
        )
        check(
            SwifQL.select(Fn.count(Distinct(CarBrands.column("id")))),
            .psql(#"SELECT count(DISTINCT "car_brands"."id")"#),
            .mysql("SELECT count(DISTINCT car_brands.id)"),
            .duck(#"SELECT count(DISTINCT "car_brands"."id")"#)
        )

        let filtered = SwifQL.select(
            Fn.count().filter(where: CarBrands.column("name") == "active")
        )
        check(
            filtered,
            .psql(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'active')"#),
            .duck(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'active')"#)
        )

        let firstPredicate = CarBrands.column("name") == "first"
        let secondPredicate = CarBrands.column("id") == "second"
        let twoPredicates = SwifQL.select(
            Fn.count().filter(where: firstPredicate, secondPredicate)
        )
        check(
            twoPredicates,
            .psql(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second')"#),
            // Render compatibility only; this does not claim native MySQL FILTER support.
            .mysql("SELECT count(*) FILTER (WHERE car_brands.name = 'first' AND car_brands.id = 'second')"),
            .duck(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second')"#)
        )

        let twoPredicatesArray = SwifQL.select(
            Fn.count().filter(where: [firstPredicate, secondPredicate])
        )
        for dialect in [SQLDialect.psql, .mysql, .duck] {
            #expect(
                twoPredicatesArray.prepare(dialect).plain
                    == twoPredicates.prepare(dialect).plain
            )
        }

        let threePredicates = SwifQL.select(
            Fn.count().filter(
                where:
                    CarBrands.column("name") == "first",
                    CarBrands.column("name") == "second",
                    CarBrands.column("name") == "third"
            )
        )
        check(
            threePredicates,
            .psql(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."name" = 'second' AND "car_brands"."name" = 'third')"#),
            .duck(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."name" = 'second' AND "car_brands"."name" = 'third')"#)
        )
        #expect(
            threePredicates.prepare(.psql).splitted.values.map { String(describing: $0) }
                == ["first", "second", "third"]
        )

        let grouped = Or {
            CarBrands.column("name") == "active"
            CarBrands.column("name") == "pending"
        }
        let groupedFilter = SwifQL.select(
            Fn.count().filter(
                where: grouped,
                CarBrands.column("id") == "selected"
            )
        )
        check(
            groupedFilter,
            .psql(#"SELECT count(*) FILTER (WHERE ("car_brands"."name" = 'active' OR "car_brands"."name" = 'pending') AND "car_brands"."id" = 'selected')"#),
            .duck(#"SELECT count(*) FILTER (WHERE ("car_brands"."name" = 'active' OR "car_brands"."name" = 'pending') AND "car_brands"."id" = 'selected')"#)
        )

        let multiFilteredWindow = SwifQL.select(
            Fn.count()
                .filter(where: firstPredicate, secondPredicate)
                .over(partitionBy: CarBrands.column("name"))
        )
        check(
            multiFilteredWindow,
            .psql(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second') OVER (PARTITION BY "car_brands"."name")"#),
            .duck(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second') OVER (PARTITION BY "car_brands"."name")"#)
        )

        let empty = SQLableParts(rawParts: [])
        let emptyFragmentFilter = SwifQL.select(
            Fn.count().filter(
                where: [
                    empty,
                    CarBrands.column("name") == "first",
                    empty,
                    CarBrands.column("id") == "second",
                    empty
                ]
            )
        )
        check(
            emptyFragmentFilter,
            .psql(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second')"#),
            .duck(#"SELECT count(*) FILTER (WHERE "car_brands"."name" = 'first' AND "car_brands"."id" = 'second')"#)
        )
        #expect(
            emptyFragmentFilter.prepare(.psql).splitted.values.map { String(describing: $0) }
                == ["first", "second"]
        )

        check(
            SwifQL.select(
                Fn.count().over(partitionBy: CarBrands.column("name"))
            ),
            .psql(#"SELECT count(*) OVER (PARTITION BY "car_brands"."name")"#),
            .mysql("SELECT count(*) OVER (PARTITION BY car_brands.name)"),
            .duck(#"SELECT count(*) OVER (PARTITION BY "car_brands"."name")"#)
        )

        let allRows = SwifQL.select(Fn.count()).prepare(.psql).splitted
        #expect(allRows.values.isEmpty)

        let composed = SwifQL.select(
            Fn.count()
                .filter(where: CarBrands.column("name") == "active")
                .over(partitionBy: CarBrands.column("id")),
            "tail"
        )
        let composedPrepared = composed.prepare(.psql).splitted
        #expect(
            composedPrepared.values.map { String(describing: $0) }
                == ["active", "tail"]
        )
    }
    
    @Test("Select div")
    func selectFnDiv() {
        check(
            SwifQL.select(Fn.div(12, 4)),
            .psql("SELECT div(12, 4)"),
            .mysql("SELECT div(12, 4)")
        )
    }
    
    @Test("Select exp")
    func selectFnExp() {
        check(
            SwifQL.select(Fn.exp(12, 4)),
            .psql("SELECT exp(12, 4)"),
            .mysql("SELECT exp(12, 4)")
        )
    }
    
    @Test("Select floor")
    func selectFnFloor() {
        check(
            SwifQL.select(Fn.floor(12)),
            .psql("SELECT floor(12)"),
            .mysql("SELECT floor(12)"),
            .duck("SELECT floor(12)")
        )
    }
    
    @Test("Select max")
    func selectFnMax() {
        check(
            SwifQL.select(Fn.max(CarBrands.column("id"))),
            .psql(#"SELECT max("car_brands"."id")"#),
            .mysql("SELECT max(car_brands.id)"),
            .duck(#"SELECT max("car_brands"."id")"#)
        )
        check(
            SwifQL.select(Fn.max(cb.column("id"))),
            .psql(#"SELECT max("cb"."id")"#),
            .mysql("SELECT max(cb.id)"),
            .duck(#"SELECT max("cb"."id")"#)
        )
    }
    
    @Test("Select min")
    func selectFnMin() {
        check(
            SwifQL.select(Fn.min(CarBrands.column("id"))),
            .psql(#"SELECT min("car_brands"."id")"#),
            .mysql("SELECT min(car_brands.id)"),
            .duck(#"SELECT min("car_brands"."id")"#)
        )
        check(
            SwifQL.select(Fn.min(cb.column("id"))),
            .psql(#"SELECT min("cb"."id")"#),
            .mysql("SELECT min(cb.id)"),
            .duck(#"SELECT min("cb"."id")"#)
        )
    }
    
    @Test("Select mod")
    func selectFnMod() {
        check(
            SwifQL.select(Fn.mod(12, 4)),
            .psql("SELECT mod(12, 4)"),
            .mysql("SELECT mod(12, 4)"),
            .duck("SELECT mod(12, 4)")
        )
    }
    
    @Test("Select power")
    func selectFnPower() {
        check(
            SwifQL.select(Fn.power(12, 4)),
            .psql("SELECT power(12, 4)"),
            .mysql("SELECT power(12, 4)"),
            .duck("SELECT power(12, 4)")
        )
    }
    
    @Test("Select random")
    func selectFnRandom() {
        check(
            SwifQL.select(Fn.random()),
            .psql("SELECT random()"),
            .mysql("SELECT random()"),
            .duck("SELECT random()")
        )
    }
    
    @Test("Select round")
    func selectFnRound() {
        check(
            SwifQL.select(Fn.round(12.43)),
            .psql("SELECT round(12.43)"),
            .mysql("SELECT round(12.43)"),
            .duck("SELECT round(12.43)")
        )
        check(
            SwifQL.select(Fn.round(12.43, 1)),
            .psql("SELECT round(12.43, 1)"),
            .mysql("SELECT round(12.43, 1)"),
            .duck("SELECT round(12.43, 1)")
        )
    }
    
    @Test("Select setSeed")
    func selectFnSetSeed() {
        check(
            SwifQL.select(Fn.setSeed(12)),
            .psql("SELECT setseed(12)"),
            .mysql("SELECT setseed(12)"),
            .duck("SELECT setseed(12)")
        )
    }
    
    @Test("Select sign")
    func selectFnSign() {
        check(
            SwifQL.select(Fn.sign(12)),
            .psql("SELECT sign(12)"),
            .mysql("SELECT sign(12)"),
            .duck("SELECT sign(12)")
        )
    }
    
    @Test("Select sqrt")
    func selectFnSqrt() {
        check(
            SwifQL.select(Fn.sqrt(16)),
            .psql("SELECT sqrt(16)"),
            .mysql("SELECT sqrt(16)"),
            .duck("SELECT sqrt(16)")
        )
    }
    
    @Test("Select sum")
    func selectFnSum() {
        check(
            SwifQL.select(Fn.sum(CarBrands.column("id"))),
            .psql(#"SELECT sum("car_brands"."id")"#),
            .mysql("SELECT sum(car_brands.id)"),
            .duck(#"SELECT sum("car_brands"."id")"#)
        )
        check(
            SwifQL.select(Fn.sum(cb.column("id"))),
            .psql(#"SELECT sum("cb"."id")"#),
            .mysql("SELECT sum(cb.id)"),
            .duck(#"SELECT sum("cb"."id")"#)
        )
    }

    @Test("Select stringAgg")
    func selectFnStringAgg() {
        check(
            SwifQL.select(Fn.stringAgg(CarBrands.column("name"), ", ")),
            .psql(#"SELECT string_agg("car_brands"."name", ', ')"#),
            .mysql("SELECT string_agg(car_brands.name, ', ')"),
            .duck(#"SELECT string_agg("car_brands"."name", ', ')"#)
        )
    }

    @Test("Select regExpReplace")
    func selectFnRegExpReplace() {
        check(
            SwifQL.select(Fn.regExpReplace("/full/path/to/filename", "^.+/", "")),
            .psql(#"SELECT regexp_replace('/full/path/to/filename', '^.+/', '')"#),
            .mysql("SELECT regexp_replace('/full/path/to/filename', '^.+/', '')"),
            .duck(#"SELECT regexp_replace('/full/path/to/filename', '^.+/', '')"#)
        )
    }
    
    // MARK: - Wave 04 PostgreSQL expression-subscript correctness

    @Test("Wave 04: column subscripts stay direct in every established dialect")
    func wave04ColumnSubscript() {
        let expression = DB.Table("items").column("scores")[1]
        check(
            SwifQL.select(expression),
            .psql(#"SELECT "items"."scores"[1]"#),
            .mysql("SELECT items.scores[1]"), // Render compatibility only.
            .duck(#"SELECT "items"."scores"[1]"#)
        )
    }

    @Test("Wave 04: aggregate subscripts group only in PostgreSQL")
    func wave04AggregateSubscript() {
        let expression = Fn.arrayAgg(DB.Column("score"))[1]
        check(
            SwifQL.select(expression),
            .psql(#"SELECT (array_agg("score"))[1]"#),
            .mysql("SELECT array_agg(score)[1]"), // Render compatibility only.
            .duck(#"SELECT array_agg("score")[1]"#)
        )
    }

    @Test("Wave 04: bound aggregate base and bound index retain value order")
    func wave04BoundAggregateSubscript() {
        let expression = Fn.arrayAgg("base")[2]
        let postgres = expression.prepare(.psql)
        #expect(postgres.plain == "(array_agg('base'))[2]")
        #expect(postgres.splitted.query == "(array_agg($1))[$2]")
        #expect(postgres.splitted.values.map { String(describing: $0) } == ["base", "2"])

        let duck = expression.prepare(.duck)
        #expect(duck.plain == "array_agg('base')[2]")
        #expect(duck.splitted.query == "array_agg($1)[$2]")
        #expect(duck.splitted.values.map { String(describing: $0) } == ["base", "2"])

        let mysql = expression.prepare(.mysql)
        #expect(mysql.plain == "array_agg('base')[2]") // Render compatibility only.
        #expect(mysql.splitted.query == "array_agg(?)[?]")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["base", "2"])

        let defaultDialect = expression.prepare(SQLDialect())
        #expect(defaultDialect.plain == "array_agg('base')[2]")
        #expect(defaultDialect.splitted.query == "array_agg(?)[?]")

        let copied = SQLableParts(parts: expression.parts)
        #expect(copied.prepare(.psql).splitted.query == postgres.splitted.query)
        #expect(copied.prepare(.psql).splitted.values.map { String(describing: $0) } == ["base", "2"])
    }

    @Test("Wave 04: JSON traversal is a general PostgreSQL subscript base")
    func wave04JSONTraversalSubscript() {
        let traversal = SQLableParts(parts: SQLPartKeyPath(
            table: "items",
            paths: ["payload", "scores"]
        ))
        let expression = traversal[1]
        #expect(expression.prepare(.psql).plain == #"("items"."payload"->'scores')[1]"#)
        #expect(expression.prepare(.psql).splitted.query == #"("items"."payload"->'scores')[$1]"#)
    }

    @Test("Wave 04: chained subscripts group only the original general base")
    func wave04ChainedSubscripts() {
        let column = DB.Table("items").column("matrix")[1][2]
        #expect(column.prepare(.psql).plain == #""items"."matrix"[1][2]"#)
        #expect(column.prepare(.psql).splitted.query == #""items"."matrix"[$1][$2]"#)

        let aggregate = Fn.arrayAgg(DB.Column("score"))[1][2]
        #expect(aggregate.prepare(.psql).plain == #"(array_agg("score"))[1][2]"#)
        #expect(aggregate.prepare(.psql).splitted.query == #"(array_agg("score"))[$1][$2]"#)
        #expect(aggregate.prepare(.duck).plain == #"array_agg("score")[1][2]"#)
        #expect(aggregate.prepare(.mysql).plain == "array_agg(score)[1][2]") // Render only.
    }

    @Test("Wave 04: non-function expression and value bases are grouped")
    func wave04OtherGeneralBases() {
        let arithmeticBase = DB.Column("left") + DB.Column("right")
        #expect(arithmeticBase.parts.count > 1)
        let expression = arithmeticBase[1]
        #expect(expression.prepare(.psql).plain == "(" + arithmeticBase.prepare(.psql).plain + ")[1]")
        #expect(expression.prepare(.duck).plain == arithmeticBase.prepare(.duck).plain + "[1]")

        let safeBase = SQLableParts(parts: SQLPartSafeValue("literal"))[1]
        #expect(safeBase.prepare(.psql).plain == "('literal')[1]")

        let boundBase = SQLableParts(parts: SQLPartUnsafeValue("literal"))[1]
        #expect(boundBase.prepare(.psql).plain == "('literal')[1]")
        #expect(boundBase.prepare(.psql).splitted.query == "($1)[$2]")
        #expect(boundBase.prepare(.psql).splitted.values.map { String(describing: $0) } == ["literal", "1"])
    }

    // MARK: - SELECT with alias in select params

    @Test("Select With Alias In Select Params")
    func selectWithAliasInSelectParams() {
        check(
            SwifQL.select("hello", =>"aaa").from(|SwifQL.select(CarBrands.column("name")).from(CarBrands.table))| => "aaa",
            .psql(#"SELECT 'hello', "aaa" FROM (SELECT "car_brands"."name" FROM "car_brands") as "aaa""#),
            .mysql("SELECT 'hello', aaa FROM (SELECT car_brands.name FROM car_brands) as aaa"),
            .duck(#"SELECT 'hello', "aaa" FROM (SELECT "car_brands"."name" FROM "car_brands") as "aaa""#)
        )
    }
}
