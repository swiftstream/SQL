@testable import SQL
import Foundation
import Testing

@Suite("Fn Tests")
struct FnTests: SwifQLTests {
    // MARK: - Fn.arrayRemove
    
    @Test("Test arrayRemove")
    func arrayRemove() {
        check(
            SwifQL.select(Fn.arrayRemove(PgArray(1,2,3,2), 2)),
            .psql("SELECT array_remove(ARRAY[1, 2, 3, 2], 2)"),
            .mysql("SELECT array_remove(ARRAY[1, 2, 3, 2], 2)")
        )
    }
    
    // MARK: - Concat
    
    @Test("Test concat")
    func concat() {
        check(
            Fn.concat("Hello ", CarBrands.column("name")),
            .psql(#"concat('Hello ', "CarBrands"."name")"#),
            .mysql("concat('Hello ', CarBrands.name)"),
            .duck(#"concat('Hello ', "CarBrands"."name")"#)
        )
        check(
            Fn.concatWS(", ", "Hello", CarBrands.column("name")),
            .psql(#"concat_ws(', ', 'Hello', "CarBrands"."name")"#),
            .mysql("concat_ws(', ', 'Hello', CarBrands.name)"),
            .duck(#"concat_ws(', ', 'Hello', "CarBrands"."name")"#)
        )
    }
    
    // MARK: - Fn.toTSVector
    
    @Test("Test toTSVector")
    func toTSVector() {
        check(
            SwifQL.select(Fn.toTSVector("english", "a fat  cat sat on a mat - it ate a fat rats")),
            .psql(#"SELECT to_tsvector('english', 'a fat  cat sat on a mat - it ate a fat rats')"#),
            .mysql("SELECT to_tsvector('english', 'a fat  cat sat on a mat - it ate a fat rats')")
        )
        check(
            SwifQL.select(Fn.toTSVector("english")),
            .psql("SELECT to_tsvector('english')"),
            .mysql("SELECT to_tsvector('english')")
        )
    }
    
    // MARK: - Fn.toTSQuery
    
    @Test("Test toTSQuery")
    func toTSQuery() {
        check(
            SwifQL.select(Fn.toTSQuery("english", "The & Fat & Rats")),
            .psql("SELECT to_tsquery('english', 'The & Fat & Rats')"),
            .mysql("SELECT to_tsquery('english', 'The & Fat & Rats')")
        )
        check(
            SwifQL.select(Fn.toTSQuery("english")),
            .psql("SELECT to_tsquery('english')"),
            .mysql("SELECT to_tsquery('english')")
        )
    }
    
    // MARK: - Fn.plainToTSQuery
    
    @Test("Test plainToTSQuery")
    func plainToTSQuery() {
        check(
            SwifQL.select(Fn.plainToTSQuery("english", "The Fat Rats")),
            .psql("SELECT plainto_tsquery('english', 'The Fat Rats')"),
            .mysql("SELECT plainto_tsquery('english', 'The Fat Rats')")
        )
        check(
            SwifQL.select(Fn.plainToTSQuery("english")),
            .psql("SELECT plainto_tsquery('english')"),
            .mysql("SELECT plainto_tsquery('english')")
        )
    }
    
    // MARK: - Fn.tsRankCD
    
    @Test("Test tsRankCD")
    func tsRankCD() {
        check(
            SwifQL.select(Fn.tsRankCD(FormattedKeyPath(CarBrands.self, "id"), Fn.toTSQuery("The Fat Rats"))),
            .psql(#"SELECT ts_rank_cd("CarBrands"."id", to_tsquery('The Fat Rats'))"#),
            .mysql("SELECT ts_rank_cd(CarBrands.id, to_tsquery('The Fat Rats'))")
        )
    }
    
    // MARK - Generate Series
    
    @Test("Test Generate Series Numbers")
    func generateSeriesNumbers() {
        check(
            SwifQL.select(Fn.generateSeries(1, 4)),
            .psql("SELECT generate_series(1, 4)"),
            .mysql("SELECT generate_series(1, 4)"),
            .duck("SELECT generate_series(1, 4)")
        )
        check(
            SwifQL.select(Fn.generateSeries(1, 4, 2)),
            .psql("SELECT generate_series(1, 4, 2)"),
            .mysql("SELECT generate_series(1, 4, 2)"),
            .duck("SELECT generate_series(1, 4, 2)")
        )
    }
    
    @Test("Test Generate Series Dates")
    func generateSeriesDates() {
        check(
            SwifQL.select(Fn.generateSeries("2019-10-01", "2019-10-04", "1 day")),
            .psql("SELECT generate_series('2019-10-01', '2019-10-04', '1 day')"),
            .mysql("SELECT generate_series('2019-10-01', '2019-10-04', '1 day')")
        )
        check(
            SwifQL.select(Fn.generateSeries("2019-10-01" => .date, "2019-10-04" => .date, "1 day")),
            .psql("SELECT generate_series('2019-10-01'::date, '2019-10-04'::date, '1 day')"),
            .mysql("SELECT generate_series('2019-10-01'::date, '2019-10-04'::date, '1 day')")
        )
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        let pdf = DateFormatter()
        pdf.calendar = Calendar(identifier: .iso8601)
        pdf.locale = Locale(identifier: "en_US_POSIX")
        pdf.timeZone = TimeZone.current
        pdf.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        let date1 = df.date(from: "2019-10-01 00:00:00")!
        let date2 = df.date(from: "2019-10-04 00:00:00")!
        check(
            SwifQL.select(Fn.generateSeries(date1, date2, "1 day")),
            .psql("SELECT generate_series(('\(pdf.string(from: date1))'::timestamptz), ('\(pdf.string(from: date2))'::timestamptz), '1 day')"),
            .mysql("SELECT generate_series(FROM_UNIXTIME(1569888000.0), FROM_UNIXTIME(1570147200.0), '1 day')")
        )
    }

    // MARK: - MySQL DATE_FORMAT

    @Test("Test dateFormat")
    func dateFormat() {
        check(
            SwifQL.select(Fn.dateFormat(CarBrands.column("createdAt"), "%y-%m")),
            .psql(#"SELECT DATE_FORMAT("CarBrands"."createdAt", '%y-%m')"#),
            .mysql("SELECT DATE_FORMAT(CarBrands.createdAt, '%y-%m')")
        )
    }

    // MARK: - Exact Base64 function

    @Test("Test fromBase64 exact SQL and bindings")
    func fromBase64() {
        let query = SwifQL.select(Fn.fromBase64("SGVsbG8="))
        check(
            query,
            .psql("SELECT from_base64('SGVsbG8=')", "SELECT from_base64($1)"),
            .mysql("SELECT FROM_BASE64('SGVsbG8=')", "SELECT FROM_BASE64(?)"),
            .duck("SELECT from_base64('SGVsbG8=')", "SELECT from_base64($1)")
        )

        #expect(query.prepare(.psql).plain.contains("from_base64"))
        #expect(!query.prepare(.psql).plain.contains("decode"))
    }

    @Test("fromBase64 keeps ordinary string binding and order")
    func fromBase64StringValues() {
        let first = "O'Reilly"
        let second = "Привет 🦆"
        let query = SwifQL.select(Fn.fromBase64(first), Fn.fromBase64(second))

        let duck = query.prepare(.duck)
        #expect(duck.plain == "SELECT from_base64('O''Reilly'), from_base64('Привет 🦆')")
        #expect(duck.splitted.query == "SELECT from_base64($1), from_base64($2)")
        #expect(duck.splitted.values[0] as? String == first)
        #expect(duck.splitted.values[1] as? String == second)

        let mysql = query.prepare(.mysql)
        #expect(mysql.splitted.query == "SELECT FROM_BASE64(?), FROM_BASE64(?)")
        #expect(mysql.splitted.values[0] as? String == first)
        #expect(mysql.splitted.values[1] as? String == second)
    }

    @Test("Historical Data parts and SQL remain unchanged")
    func historicalDataParts() {
        let data = Data([1, 2, 3])
        let expectedTypes = [
            "SQLPartOperator",
            "SQLPartOperator",
            "SQLPartSafeValue",
            "SQLPartOperator",
            "SQLPartOperator",
            "SQLPartSafeValue",
            "SQLPartOperator"
        ]

        #expect(data.parts.count == 7)
        #expect(data.parts.map { String(describing: type(of: $0)) } == expectedTypes)

        let query = SwifQL.select(data)
        let expectedSQL = "SELECT decode('AQID', 'base64')"
        #expect(query.prepare(.psql).plain == expectedSQL)
        #expect(query.prepare(.psql).splitted.query == expectedSQL)
        #expect(query.prepare(.mysql).plain == expectedSQL)
        #expect(query.prepare(.mysql).splitted.query == expectedSQL)
    }
}
