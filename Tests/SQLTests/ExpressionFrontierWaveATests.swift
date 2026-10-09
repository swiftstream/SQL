import Foundation
import Testing
@testable import SQL

private struct ExpressionFrontierWaveATable: Table {
    static var tableName: String { "wave_a" }

    @Column("name")
    var name: String

    @Column("created_at")
    var createdAt: String

    init() {}
}

private final class WaveAPartsProbe: SQLable {
    private let snapshot: [SQLPart]
    private(set) var evaluations = 0

    init(_ snapshot: [SQLPart]) {
        self.snapshot = snapshot
    }

    var parts: [SQLPart] {
        evaluations += 1
        return snapshot
    }
}

@Suite("Expression Frontier 02 Wave A")
struct ExpressionFrontierWaveATests: SwifQLTests {
    private typealias Fixture = ExpressionFrontierWaveATable

    @Test("Exact binary operator snapshots operands once and preserves bind order")
    func exactBinarySnapshotAndBindOrder() {
        let lhs = WaveAPartsProbe([SQLPartUnsafeValue("left")])
        let rhs = WaveAPartsProbe([SQLPartUnsafeValue("right")])

        let expression = lhs.op(.custom("@?"), rhs)

        #expect(lhs.evaluations == 1)
        #expect(rhs.evaluations == 1)

        check(
            expression,
            .psql("('left' @? 'right')", "($1 @? $2)"),
            .mysql("('left' @? 'right')", "(? @? ?)"),
            .duck("('left' @? 'right')", "($1 @? $2)")
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let values = expression.prepare(dialect).splitted.values
            #expect(values.count == 2)
            #expect(values[0] as? String == "left")
            #expect(values[1] as? String == "right")
        }

        #expect(lhs.evaluations == 1)
        #expect(rhs.evaluations == 1)
    }

    @Test("Exact binary escape preserves all EF02 punctuation tokens and grouping")
    func exactBinaryTokenMatrix() {
        let tokens = ["->", "->>", "#>", "#>>", "@?", "@@", "&&", "<<", ">>", "&<", "&>", "-|-"]

        for token in tokens {
            let expression = Path.Column("lhs").op(.custom(token), Path.Column("rhs"))
            #expect(expression.prepare(.psql).plain == "(\"lhs\" \(token) \"rhs\")")
            #expect(expression.prepare(.mysql).plain == "(lhs \(token) rhs)")
            #expect(expression.prepare(.duck).plain == "(\"lhs\" \(token) \"rhs\")")
        }

        let nested = Path.Column("lhs")
            .op(.custom("&&"), Path.Column("middle"))
            .op(.custom("-|-"), Path.Column("rhs"))

        #expect(nested.prepare(.psql).plain == "((\"lhs\" && \"middle\") -|- \"rhs\")")
    }

    @Test("COLLATE is structural in builder and inline forms")
    func collateStructural() {
        let builder = Select {
            Fixture.$name
            Collate("C")
            As("displayName")
        }

        check(
            builder,
            .psql("SELECT \"wave_a\".\"name\" COLLATE \"C\" as \"displayName\""),
            .mysql("SELECT wave_a.name COLLATE `C` as displayName"),
            .duck("SELECT \"wave_a\".\"name\" COLLATE \"C\" as \"displayName\"")
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            #expect(builder.prepare(dialect).splitted.values.isEmpty)
        }

        let qualified = Collate(
            Fixture.$name,
            Path.Identifier(schema: "pg_catalog", name: "C")
        )

        #expect(
            qualified.prepare(.psql).plain
                == "\"wave_a\".\"name\" COLLATE \"pg_catalog\".\"C\""
        )
        #expect(qualified.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("AT TIME ZONE remains bindable and supports repeated SELECT continuation")
    func timeZoneContinuationAndOrder() {
        let builder = Select {
            Fixture.$createdAt
            AtTimeZone("UTC")
            AtTimeZone("Europe/Amsterdam")
            As("localized")
        }

        check(
            builder,
            .psql(
                "SELECT \"wave_a\".\"created_at\" AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Amsterdam' as \"localized\"",
                "SELECT \"wave_a\".\"created_at\" AT TIME ZONE $1 AT TIME ZONE $2 as \"localized\""
            ),
            .mysql(
                "SELECT wave_a.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Amsterdam' as localized",
                "SELECT wave_a.created_at AT TIME ZONE ? AT TIME ZONE ? as localized"
            ),
            .duck(
                "SELECT \"wave_a\".\"created_at\" AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Amsterdam' as \"localized\"",
                "SELECT \"wave_a\".\"created_at\" AT TIME ZONE $1 AT TIME ZONE $2 as \"localized\""
            )
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let values = builder.prepare(dialect).splitted.values
            #expect(values.count == 2)
            #expect(values[0] as? String == "UTC")
            #expect(values[1] as? String == "Europe/Amsterdam")
        }

        let inline = AtTimeZone(Fixture.$createdAt, "UTC")
        #expect(
            inline.prepare(.psql).splitted.query
                == "\"wave_a\".\"created_at\" AT TIME ZONE $1"
        )
        #expect(inline.prepare(.psql).splitted.values.first as? String == "UTC")
    }

    @Test("AT LOCAL stays rhs-free and control-flow groups preserve later projections")
    func atLocalAndControlFlow() {
        let includeName = true

        let query = Select {
            if includeName {
                Fixture.$createdAt
                AtLocal()
                As("localCreatedAt")
            }

            Fixture.$name
        }

        check(
            query,
            .psql("SELECT \"wave_a\".\"created_at\" AT LOCAL as \"localCreatedAt\", \"wave_a\".\"name\""),
            .mysql("SELECT wave_a.created_at AT LOCAL as localCreatedAt, wave_a.name"),
            .duck("SELECT \"wave_a\".\"created_at\" AT LOCAL as \"localCreatedAt\", \"wave_a\".\"name\"")
        )

        #expect(query.prepare(.psql).splitted.values.isEmpty)

        let inline = AtLocal(Fixture.$createdAt)
        #expect(inline.prepare(.psql).plain == "\"wave_a\".\"created_at\" AT LOCAL")
    }
}
