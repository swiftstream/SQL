import Testing
@testable import SwifQL

private final class DQ05ValuesEvaluationCounter {
    var count = 0
}

private struct DQ05CountedRowField: SwifQLable {
    let counter: DQ05ValuesEvaluationCounter

    var parts: [SwifQLPart] {
        counter.count += 1
        return "snapshot".parts
    }
}

private struct DQ052CountedColumnPath: SwifQLable {
    let counter: DQ05ValuesEvaluationCounter

    var parts: [SwifQLPart] {
        counter.count += 1
        return [SwifQLPartKeyPath(table: "User", paths: ["createdAt"])]
    }
}

private struct DQ052IdentifierColumnUser: Table {
    static var tableName: String { "User" }

    @Column("id") var id: Int
    @Column("name") var name: String

    init() {}
}

@Suite("Declarative Row and VALUES authoring")
struct DeclarativeQueryValuesTests: SwifQLTests {
    @Test("Row builder and concise forms have the same expression SQL and binds")
    func rowBuilderAndConciseFormsMatch() {
        let concise = Row("NL", "Amsterdam")
        let built = Row {
            "NL"
            "Amsterdam"
        }

        for row in [concise, built] {
            let plain = row.prepare(.psql)
            #expect(plain.plain == "ROW('NL', 'Amsterdam')")
            #expect(plain.splitted.query == "ROW($1, $2)")
            #expect(plain.splitted.values.map { String(describing: $0) } == ["NL", "Amsterdam"])
            #expect(row.prepare(.mysql).plain == "ROW('NL', 'Amsterdam')")
            #expect(row.prepare(.duck).plain == "ROW('NL', 'Amsterdam')")
        }
    }

    @Test("VALUES builder and concise forms preserve SQL and bind order")
    func valuesBuilderAndConciseFormsMatch() {
        let built = Values {
            Row("admin", 100)
            Row("moderator", 50)
        }
        let concise = Values(Row("admin", 100), Row("moderator", 50))
        let expectedValues = ["admin", "100", "moderator", "50"]

        for values in [built, concise] {
            let psql = values.prepare(.psql)
            #expect(psql.plain == "VALUES ('admin', 100), ('moderator', 50)")
            #expect(psql.splitted.query == "VALUES ($1, $2), ($3, $4)")
            #expect(psql.splitted.values.map { String(describing: $0) } == expectedValues)

            let mysql = values.prepare(.mysql)
            #expect(mysql.plain == "VALUES ROW('admin', 100), ROW('moderator', 50)")
            #expect(mysql.splitted.query == "VALUES ROW(?, ?), ROW(?, ?)")
            #expect(mysql.splitted.values.map { String(describing: $0) } == expectedValues)

            let duck = values.prepare(.duck)
            #expect(duck.plain == "VALUES ('admin', 100), ('moderator', 50)")
            #expect(duck.splitted.query == "VALUES ($1, $2), ($3, $4)")
            #expect(duck.splitted.values.map { String(describing: $0) } == expectedValues)
        }

        let rooted = SwifQL {
            Values {
                Row("admin", 100)
                Row("moderator", 50)
            }
        }
        #expect(rooted.prepare(.psql).plain == "VALUES ('admin', 100), ('moderator', 50)")
        #expect(rooted.prepare(.psql).splitted.values.map { String(describing: $0) } == expectedValues)
    }

    @Test("Builder control flow filters Row fields and VALUES rows")
    func builderControlFlowFiltersFieldsAndRows() {
        let includeCity = true
        let row = Row {
            "NL"
            if includeCity {
                "Amsterdam"
            }
        }
        #expect(row.prepare(.psql).plain == "ROW('NL', 'Amsterdam')")

        let includeModerator = false
        let values = Values {
            Row("admin", 100)
            if includeModerator {
                Row("moderator", 50)
            }
        }
        #expect(values.prepare(.psql).plain == "VALUES ('admin', 100)")
        #expect(values.prepare(.psql).splitted.values.map { String(describing: $0) } == ["admin", "100"])
    }

    @Test("Mixed Rows retain Default markers until a later owner consumes them")
    func mixedRowsCanBeConstructedWithoutLowering() {
        let first = Row(1, "John", Default())
        let values = Values {
            first
            Row(2, "Kate", Default())
        }

        #expect(first.fields.count == 3)
        #expect(values.rows.count == 2)
        let hasDefaultMarker: Bool = {
            if case .defaultKeyword = first.fields[2] { return true }
            return false
        }()
        #expect(hasDefaultMarker)
    }

    @Test("Row fields snapshot each SwifQLable parts value once")
    func rowFieldsSnapshotPartsOnce() {
        let counter = DQ05ValuesEvaluationCounter()
        let row = Row(DQ05CountedRowField(counter: counter))
        #expect(counter.count == 1)
        #expect(row.prepare(.psql).plain == "ROW('snapshot')")
        #expect(counter.count == 1)

        let values = Values {
            row
            Row("second")
        }
        #expect(values.prepare(.psql).plain == "VALUES ('snapshot'), ('second')")
        #expect(counter.count == 1)
    }

    @Test("Identifier Columns accepts structural column paths and snapshots them once")
    func identifierColumnsAcceptStructuralPaths() {
        let counter = DQ05ValuesEvaluationCounter()
        let request = Columns {
            Path.Column("id")
            Path.Column("name")
            DQ052CountedColumnPath(counter: counter)
        }

        #expect(counter.count == 1)
        #expect(request.names == ["id", "name", "createdAt"])

        let keyPathRequest = Columns {
            DQ052IdentifierColumnUser.$id
            DQ052IdentifierColumnUser.$name
        }
        #expect(keyPathRequest.names == ["id", "name"])

        let stringRequest = Columns {
            "role"
            "priority"
        }
        #expect(stringRequest.names == ["role", "priority"])
        #expect(Columns("role", "priority").names == ["role", "priority"])
    }

    @Test("INSERT consumes semantic DEFAULT fields without binding them")
    func insertOwnsDefaultLowering() {
        let pathColumns = SwifQL {
            Insert(Path.Table("User")) {
                Columns { Path.Column("id"); Path.Column("name"); Path.Column("createdAt") }
                Values {
                    Row(1, "John", Default())
                    Row(2, "Kate", Default())
                }
            }
        }
        let stringColumns = Insert(Path.Table("User")) {
            Columns { "id"; "name"; "createdAt" }
            Values { Row(1, "John", Default()); Row(2, "Kate", Default()) }
        }

        let expectedPsql = #"INSERT INTO "User" ("id", "name", "createdAt") VALUES (1, 'John', DEFAULT), (2, 'Kate', DEFAULT)"#
        let expectedPsqlSplit = #"INSERT INTO "User" ("id", "name", "createdAt") VALUES ($1, $2, DEFAULT), ($3, $4, DEFAULT)"#
        let expectedValues = ["1", "John", "2", "Kate"]

        for query in [pathColumns, stringColumns] {
            let psql = query.prepare(.psql)
            #expect(psql.plain == expectedPsql)
            #expect(psql.splitted.query == expectedPsqlSplit)
            #expect(psql.splitted.values.map { String(describing: $0) } == expectedValues)

            let mysql = query.prepare(.mysql)
            #expect(mysql.plain == "INSERT INTO User (id, name, createdAt) VALUES ROW(1, 'John', DEFAULT), ROW(2, 'Kate', DEFAULT)")
            #expect(mysql.splitted.query == "INSERT INTO User (id, name, createdAt) VALUES ROW(?, ?, DEFAULT), ROW(?, ?, DEFAULT)")
            #expect(mysql.splitted.values.map { String(describing: $0) } == expectedValues)

            let duck = query.prepare(.duck)
            #expect(duck.plain == expectedPsql)
            #expect(duck.splitted.query == expectedPsqlSplit)
            #expect(duck.splitted.values.map { String(describing: $0) } == expectedValues)
        }
    }
}
