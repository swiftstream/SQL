import SQL
import Testing

private struct UsersQuery: SQLQuery {
    let active: Bool
    let email: String?

    var query: Query {
        Select {
            Path.Column("id")
            Path.Column("email")
        }

        From {
            Path.Table("users")
        }

        Where {
            Path.Column("active") == active

            if let email {
                Path.Column("email") == email
            }
        }
    }
}

private func expectEquivalent(
    _ lhs: any SQLable,
    _ rhs: any SQLable,
    dialect: SQLDialect
) {
    let left = lhs.prepare(dialect)
    let right = rhs.prepare(dialect)

    #expect(left.plain == right.plain)
    #expect(left.splitted.query == right.splitted.query)
    #expect(left.splitted.values.map { String(describing: $0) } == right.splitted.values.map { String(describing: $0) })
}

private func containsForbiddenCarrier(in parts: [SQLPart]) -> Bool {
    parts.contains { part in
        let reflectedName = String(reflecting: type(of: part))
        if reflectedName.contains("SQLQuery") || reflectedName.contains("SQLBuilder") {
            return true
        }
        guard let frame = part as? SQLStructuralFramePart else {
            return false
        }
        return containsForbiddenCarrier(in: frame.children)
    }
}

@Suite("SQLQuery")
struct SQLQueryTests {
    @Test("protocol builder inheritance and conditional omission")
    func builderInheritanceAndConditionalOmission() {
        let withEmail = UsersQuery(active: true, email: "john@example.com")
        let withoutEmail = UsersQuery(active: true, email: nil)
        let withEmailPrepared = withEmail.prepare(.psql)
        let withoutEmailPrepared = withoutEmail.prepare(.psql)

        #expect(withEmailPrepared.splitted.values.map { String(describing: $0) } == ["john@example.com"])
        #expect(withoutEmailPrepared.splitted.values.isEmpty)
        #expect(withEmailPrepared.splitted.query.contains(#""active" = TRUE"#))
        #expect(withEmailPrepared.splitted.query.contains(#"AND "email" = $1"#))
        #expect(withoutEmailPrepared.splitted.query.contains(#"WHERE "active" = TRUE"#))
        #expect(!withoutEmailPrepared.splitted.query.contains(" AND "))
    }

    @Test("direct preparation matches the underlying SQL across dialects")
    func directPreparationEquivalence() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            expectEquivalent(queryValue, queryValue.query, dialect: dialect)
        }
    }

    @Test("parts forward the ordinary structural representation")
    func structuralForwarding() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")
        let forwardedParts = queryValue.parts
        let queryParts = queryValue.query.parts
        let forwardedRoot = forwardedParts.first as? SQLStructuralFramePart
        let queryRoot = queryParts.first as? SQLStructuralFramePart

        #expect(forwardedParts.count == queryParts.count)
        #expect(forwardedRoot?.region == .statement)
        #expect(queryRoot?.region == .statement)
        expectEquivalent(queryValue, queryValue.query, dialect: .psql)
        #expect(!containsForbiddenCarrier(in: forwardedParts))
        #expect(!containsForbiddenCarrier(in: queryParts))
    }

    @Test("FROM source alias preserves nested statement structure")
    func fromSourceAndAlias() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")
        let reusable = From { queryValue.as("activeUsers") }
        let direct = From { queryValue.query.as("activeUsers") }

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            expectEquivalent(reusable, direct, dialect: dialect)
        }

        let postgresSplit = reusable.prepare(.psql).splitted.query
        #expect(postgresSplit.contains("FROM (SELECT "))
        #expect(postgresSplit.contains(#") as "activeUsers""#))
        #expect(reusable.prepare(.psql).splitted.values.map { String(describing: $0) } == ["john@example.com"])
    }

    @Test("JOIN source and scalar SELECT projection preserve composition")
    func joinAndProjectionComposition() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")
        let reusableJoin = From {
            Path.Table("outer")
            Join(.left, queryValue.as("activeUsers"))
            On(Path.Column("enabled") == "yes")
        }
        let directJoin = From {
            Path.Table("outer")
            Join(.left, queryValue.query.as("activeUsers"))
            On(Path.Column("enabled") == "yes")
        }

        expectEquivalent(reusableJoin, directJoin, dialect: .psql)
        #expect(reusableJoin.prepare(.psql).splitted.values.map { String(describing: $0) } == ["john@example.com", "yes"])

        let reusableProjection = Select {
            queryValue
            "outside"
        }
        let directProjection = Select {
            queryValue.query
            "outside"
        }

        expectEquivalent(reusableProjection, directProjection, dialect: .psql)
        #expect(reusableProjection.prepare(.psql).splitted.values.map { String(describing: $0) } == ["john@example.com", "outside"])
    }

    @Test("IN and EXISTS use generic SQLable composition")
    func inAndExistsComposition() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")
        let reusableIn = Path.Column("candidate").in(queryValue)
        let directIn = Path.Column("candidate").in(queryValue.query)
        let reusableExists = SQL.exists(queryValue)
        let directExists = SQL.exists(queryValue.query)

        expectEquivalent(reusableIn, directIn, dialect: .psql)
        expectEquivalent(reusableExists, directExists, dialect: .psql)
    }

    @Test("direct root composition keeps one ordinary statement root")
    func directRootComposition() {
        let queryValue = UsersQuery(active: true, email: "john@example.com")
        let reusable: SQLContent = SQL { queryValue }
        let direct: SQLContent = SQL { queryValue.query }
        let rootFrames = reusable.parts.compactMap { $0 as? SQLStructuralFramePart }

        expectEquivalent(reusable, direct, dialect: .psql)
        #expect(rootFrames.count == 1)
        #expect(rootFrames.first?.region == .statement)
        #expect(!containsForbiddenCarrier(in: reusable.parts))
    }
}
