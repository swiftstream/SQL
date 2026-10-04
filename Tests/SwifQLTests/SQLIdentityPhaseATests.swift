import SwifQL
import Testing

private struct SQLIdentityPhaseACustom: SQLable {
    var parts: [SQLPart] {
        [SQLPartOperator.custom("PHASE_A_CUSTOM")]
    }
}

private struct SQLIdentityPhaseALegacyCustom: SwifQLable {
    var parts: [SwifQLPart] {
        [SwifQLPartOperator.custom("PHASE_A_LEGACY")]
    }
}

private extension SwifQLable {
    var sqlIdentityPhaseALegacyExtensionMarker: Bool { true }
}

@Suite("SQL major identity Phase A")
struct SQLIdentityPhaseATests {
    @Test("Concrete SQL supports declarative and fluent roots")
    func concreteSQLRoots() {
        let declarative: SQL = SQL {
            Select { Path.Column("id") }
            From { Path.Table("users") }
            Where { Path.Column("active") == true }
        }

        let fluent: SQLable = SQL.root
            .select(Path.Column("id"))
            .from(Path.Table("users"))
            .where(Path.Column("active") == true)

        #expect(declarative.prepare(.psql).plain == fluent.prepare(.psql).plain)
        #expect(declarative.prepare(.psql).splitted.values.count == fluent.prepare(.psql).splitted.values.count)
    }

    @Test("Canonical protocol and prepared types are first-class")
    func canonicalTypes() {
        let custom: any SQLable = SQLIdentityPhaseACustom()
        let prepared: SQLPrepared = custom.prepare(.psql)

        #expect(prepared.plain == "PHASE_A_CUSTOM")
        #expect(custom.parts.count == 1)
    }

    @Test("Deprecated root wrappers preserve canonical SQL behavior")
    func legacyRootWrappers() {
        let canonical = SQL.root.select(Path.Column("id"))
        let legacyFluent = SwifQL.select(Path.Column("id"))

        let canonicalBuilder: SQL = SQL {
            Select { Path.Column("id") }
        }
        let legacyBuilder = SwifQL {
            Select { Path.Column("id") }
        }
        let legacyUnary = SwifQL(canonicalBuilder)

        #expect(legacyFluent.prepare(.psql).plain == canonical.prepare(.psql).plain)
        #expect(legacyBuilder.prepare(.psql).plain == canonicalBuilder.prepare(.psql).plain)
        #expect(legacyUnary.prepare(.psql).plain == canonicalBuilder.prepare(.psql).plain)
    }

    @Test("Deprecated protocol aliases preserve one protocol identity")
    func legacyProtocolAliasIdentity() {
        let legacy: any SwifQLable = SQLIdentityPhaseALegacyCustom()
        let canonical: any SQLable = SQLIdentityPhaseALegacyCustom()

        #expect(legacy.prepare(.psql).plain == "PHASE_A_LEGACY")
        #expect(canonical.prepare(.psql).plain == "PHASE_A_LEGACY")
        #expect(canonical.sqlIdentityPhaseALegacyExtensionMarker)
    }

    @Test("Deprecated part and prepared aliases remain assignable")
    func legacyTypeAliases() {
        let part: SwifQLPart = SQLPartOperator.custom("LEGACY_PART")
        let parts: [SwifQLPart] = [part]
        let value: any SwifQLable = SQLableParts(parts: parts)
        let prepared: SwifQLPrepared = value.prepare(.psql)

        #expect(prepared.plain == "LEGACY_PART")
    }
}
