import Testing
import SQL

private struct Todo: Table {
    @Column("id") var id: Int
    init() {}
}

private struct UserProfile: Table { init() {} }
private struct UserId: Table { init() {} }
private struct URLValue: Table { init() {} }
private struct HTTPServer: Table { init() {} }
private struct URL: Table { init() {} }
private struct X: Table { init() {} }
private struct alreadyLower: Table { init() {} }
private struct Éclair: Table { init() {} }
private struct Item٢Value: Table { init() {} }
private struct existing__snake: Table { init() {} }

private enum LegacyTables {
    struct ExplicitTableName: Table {
        static var tableName: String { "MiXeD_Name" }
        @Column("id") var id: Int
        init() {}
    }
}

@Suite("Simple table-name design")
struct TableNameNamingDesignTests {
    @Test("Type names map to lower snake case without acronym splitting errors")
    func requiredNameMatrix() {
        #expect(Todo.tableName == "todo")
        #expect(UserProfile.tableName == "user_profile")
        #expect(URLValue.tableName == "url_value")
        #expect(HTTPServer.tableName == "http_server")
        #expect(UserId.tableName == "user_id")
        #expect(URL.tableName == "url")
        #expect(X.tableName == "x")
        #expect(alreadyLower.tableName == "already_lower")
        #expect(Éclair.tableName == "éclair")
        #expect(Item٢Value.tableName == "item٢_value")
        #expect(existing__snake.tableName == "existing_snake")
    }

    @Test("AnyTable.column and Table dynamic-member paths use the default in all dialects")
    func defaultNamePropagatesAcrossDialects() {
        let formatted = Todo.column("id")
        let projected = Todo.$id

        for query in [formatted, projected] {
            #expect(query.prepare(.psql).plain == #""todo"."id""#)
            #expect(query.prepare(.mysql).plain == "todo.id")
            #expect(query.prepare(.duck).plain == #""todo"."id""#)
        }
    }

    @Test("An explicit tableName override remains exact in all dialects")
    func explicitTableNameOverrideIsUnchanged() {
        let model = LegacyTables.ExplicitTableName.self
        #expect(model.tableName == "MiXeD_Name")

        let query = LegacyTables.ExplicitTableName.column("id")
        #expect(query.prepare(.psql).plain == #""MiXeD_Name"."id""#)
        #expect(query.prepare(.mysql).plain == "MiXeD_Name.id")
        #expect(query.prepare(.duck).plain == #""MiXeD_Name"."id""#)
    }
}
