@testable import SQL
import Testing

@Suite("Established operator compatibility")
struct EstablishedOperatorCompatibilityTests {
    private final class LegacyDefaultDialect: SQLDialect {}

    private final class CustomDialect: SQLDialect {
        override func hybridOperator(_ hybrid: SwifQLHybridOperator) -> SwifQLPartOperator {
            SwifQLPartOperator("custom()")
        }
    }

    private final class RepresentationKeyDialect: SQLDialect {
        private let key: SwifQLHybridRepresentationKey

        init(key: SwifQLHybridRepresentationKey) {
            self.key = key
            super.init()
        }

        override var hybridRepresentationKey: SwifQLHybridRepresentationKey? {
            key
        }
    }

    @Test("PostgreSQL and MySQL comparison rendering stays unchanged")
    func establishedComparison() {
        let nested = FormattedKeyPath("events", "payload", "profile", "name")
        let query = nested == "Ada"
        #expect(query.prepare(.psql).plain == #""events"."payload"->'profile'->'name' = 'Ada'"#)
        #expect(query.prepare(.mysql).plain == "events.name = 'Ada'")
    }

    @Test("Hybrid dialect hook remains open to downstream dialects")
    func hybridDialectHook() {
        let hybrid = SwifQLHybridOperator(SwifQLPartOperator("pg()"), SwifQLPartOperator("mysql()"))
        #expect(hybrid.prepare(CustomDialect()).plain == "custom()")
    }

    @Test("Downstream dialects select open hybrid representations without whole-hook overrides")
    func openHybridDialectRepresentation() {
        let key = SwifQLHybridRepresentationKey(
            namespace: "example.vendor",
            name: "fourth dialect"
        )
        let hybrid = SwifQLHybridOperator(
            representations: [key: SwifQLPartOperator("fourth()")]
        )

        #expect(
            hybrid.prepare(RepresentationKeyDialect(key: key)).plain
                == "fourth()"
        )
    }

    @Test("Legacy dialects without a representation override keep MySQL fallback")
    func legacyHybridFallback() {
        let hybrid = SwifQLHybridOperator(
            SwifQLPartOperator("pg()"),
            SwifQLPartOperator("mysql()")
        )

        #expect(hybrid.prepare(LegacyDefaultDialect()).plain == "mysql()")
    }

    @Test("Legacy custom dialects retain default contextual value binding")
    func legacyContextualValueBinding() {
        let star = SwifQL.asterisk.glob("metric*").prepare(CustomDialect()).splitted
        #expect(star.query == "* GLOB ?")
        #expect(star.values[0] as? String == "metric*")

        let ordinary = SwifQLableParts(parts: SwifQLPartColumn("metric"))
            .similarTo("metric.*")
            .prepare(CustomDialect())
            .splitted
        #expect(ordinary.query == "metric SIMILAR TO ?")
        #expect(ordinary.values[0] as? String == "metric.*")
    }

    @Test("Legacy custom dialects inherit structural star modifier lowering")
    func legacyStarModifierLowering() {
        let query = SwifQL.asterisk.replace(
            StarReplacement("fallback", as: "value")
        )
        let prepared = query.prepare(CustomDialect()).splitted

        #expect(prepared.query == "* REPLACE (? as value)")
        #expect(prepared.values[0] as? String == "fallback")
    }
}
