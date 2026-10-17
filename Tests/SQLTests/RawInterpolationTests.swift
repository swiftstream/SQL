import Foundation
import Testing
@testable import SQL

private struct RawEncodedFixture: Encodable, Equatable {
    let id: Int
    let label: String
}

private final class DistinctRawMarkerDialect: SQLDialect {
    override var bindSymbol: String { "%%%" }

    override func bindKey(_ index: Int) -> String {
        "@raw\(index)"
    }
}

private func rawFragment<T: Encodable>(_ value: T) -> SQLRaw {
    "helper=\(bind: value)"
}

private func optionalIntValue(_ value: Encodable) -> Int?? {
    value as? Optional<Int>
}

private func completeOccurrences(
    _ observed: SQLObservedPrepared
) -> [SQLUnsafeValueOccurrence] {
    switch observed.unsafeValueTrace {
    case let .complete(occurrences):
        return occurrences
    case .unavailable:
        Issue.record("Expected a complete unsafe-value trace")
        return []
    }
}

@Suite("Bind-aware raw SQL interpolation")
struct RawInterpolationTests {
    @Test("R01 Empty, no-bind, multiline, and Unicode literals are preserved")
    func literalPreservation() {
        let empty: SQLRaw = ""
        let literal: SQLRaw = "SELECT  π, '雪'\nFROM events\tWHERE note = 'café'"
        let interpolation = SQLRaw.StringInterpolation(
            literalCapacity: 0,
            interpolationCount: 0
        )
        let emptyInterpolation = SQLRaw(stringInterpolation: interpolation)

        #expect(empty.prepare(.psql).plain.isEmpty)
        #expect(emptyInterpolation.prepare(.psql).plain.isEmpty)
        #expect(literal.prepare(.psql).plain == "SELECT  π, '雪'\nFROM events\tWHERE note = 'café'")
        #expect(literal.prepare(.psql).splitted.query == literal.prepare(.psql).plain)
    }

    @Test("R02 Binds at fragment boundaries and in adjacent and repeated positions")
    func bindPositionsAndRepetition() {
        let first: SQLRaw = "\(bind: 1)tail"
        let last: SQLRaw = "head\(bind: 2)"
        let adjacent: SQLRaw = "\(bind: 3)\(bind: 4)"
        let repeated: SQLRaw = "x=\(bind: 7), y=\(bind: 7), z=\(bind: 9)"

        #expect(first.prepare(.psql).plain == "1tail")
        #expect(first.prepare(.psql).splitted.query == "$1tail")
        #expect(last.prepare(.psql).plain == "head2")
        #expect(last.prepare(.psql).splitted.query == "head$1")
        #expect(adjacent.prepare(.psql).splitted.query == "$1$2")

        let split = repeated.prepare(.psql).splitted
        #expect(split.query == "x=$1, y=$2, z=$3")
        #expect(split.values.count == 3)
        #expect(split.values[0] as? Int == 7)
        #expect(split.values[1] as? Int == 7)
        #expect(split.values[2] as? Int == 9)
    }

    @Test("R03 SQLRaw copies, reuse, erasure, and helper composition preserve binds")
    func valueCompositionAndErasure() {
        let id = 41
        let fragment: SQLRaw = "id=\(bind: id)"
        let copy = fragment
        let erased: any SQLable = copy
        let reused = SQLableParts(
            parts: fragment.parts + [SQLPartOperator("|")] + copy.parts
        )
        let helper = rawFragment(id)

        #expect(erased.prepare(.psql).splitted.query == "id=$1")
        #expect(helper.prepare(.psql).splitted.query == "helper=$1")
        #expect(reused.prepare(.psql).splitted.query == "id=$1|id=$2")
        #expect(reused.prepare(.psql).splitted.values.count == 2)
        #expect(reused.prepare(.psql).splitted.values.allSatisfy { $0 as? Int == id })
    }

    @Test("R04 Scalar values keep existing rendering and ordered bind values")
    func scalarValueDomain() {
        let signed: Int16 = -12
        let unsigned: UInt8 = 8
        let float: Float = 1.5
        let double: Double = 2.5
        let name = "Ada"
        let active = true
        let uuid = UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000")!
        let decimal = Decimal(string: "12.5")!
        let raw: SQLRaw = "i=\(bind: 7)|s=\(bind: signed)|u=\(bind: unsigned)|f=\(bind: float)|d=\(bind: double)|name=\(bind: name)|active=\(bind: active)|uuid=\(bind: uuid)|amount=\(bind: decimal)"
        let expectedPlain = "i=7|s=-12|u=8|f=1.5|d=2.5|name='Ada'|active=TRUE|uuid='550E8400-E29B-41D4-A716-446655440000'|amount=12.5"

        for dialect in SQLDialect.all {
            let split = raw.prepare(dialect).splitted
            let keys = (1...9).map { dialect == .mysql ? "?" : "$\($0)" }
            #expect(raw.prepare(dialect).plain == expectedPlain)
            #expect(split.query == "i=\(keys[0])|s=\(keys[1])|u=\(keys[2])|f=\(keys[3])|d=\(keys[4])|name=\(keys[5])|active=\(keys[6])|uuid=\(keys[7])|amount=\(keys[8])")
            #expect(split.values.count == 9)
            #expect(split.values[0] as? Int == 7)
            #expect(split.values[1] as? Int16 == signed)
            #expect(split.values[2] as? UInt8 == unsigned)
            #expect(split.values[3] as? Float == float)
            #expect(split.values[4] as? Double == double)
            #expect(split.values[5] as? String == name)
            #expect(split.values[6] as? Bool == active)
            #expect(split.values[7] as? UUID == uuid)
            #expect(split.values[8] as? Decimal == decimal)
        }
    }

    @Test("R05 Typed Optional some and none each remain one original bind")
    func optionalValuesRemainTypedAndBound() {
        let some: Int? = 7
        let none: Int? = nil
        let raw: SQLRaw = "some=\(bind: some)|none=\(bind: none)"
        let unsafeParts = raw.parts.compactMap { $0 as? SQLPartUnsafeValue }
        let split = raw.prepare(.psql).splitted

        #expect(unsafeParts.count == 2)
        #expect(optionalIntValue(unsafeParts[0].unsafeValue) == .some(.some(7)))
        #expect(optionalIntValue(unsafeParts[1].unsafeValue) == .some(.none))
        #expect(split.query == "some=$1|none=$2")
        #expect(split.values.count == 2)
        #expect(optionalIntValue(split.values[0]) == .some(.some(7)))
        #expect(optionalIntValue(split.values[1]) == .some(.none))
    }

    @Test("R06 Date, Data, collections, and custom Encodable values remain one bind")
    func encodableValuesRemainSingleBinds() {
        let date = Date(timeIntervalSince1970: 0)
        let data = Data([0, 127, 255])
        let integers = [1, 2, 3]
        let strings = ["red", "green"]
        let custom = RawEncodedFixture(id: 5, label: "five")
        let raw: SQLRaw = "date=\(bind: date)|data=\(bind: data)|ints=\(bind: integers)|strings=\(bind: strings)|custom=\(bind: custom)"
        let expectedPlain = "date='<unsafe value>'|data='<unsafe value>'|ints='<unsafe value>'|strings='<unsafe value>'|custom='<unsafe value>'"

        for dialect in SQLDialect.all {
            let prepared = raw.prepare(dialect)
            let keys = (1...5).map { dialect == .mysql ? "?" : "$\($0)" }
            #expect(prepared.plain == expectedPlain)
            #expect(prepared.splitted.query == "date=\(keys[0])|data=\(keys[1])|ints=\(keys[2])|strings=\(keys[3])|custom=\(keys[4])")
            #expect(prepared.splitted.values.count == 5)
            #expect(prepared.splitted.values[0] as? Date == date)
            #expect(prepared.splitted.values[1] as? Data == data)
            #expect(prepared.splitted.values[2] as? [Int] == integers)
            #expect(prepared.splitted.values[3] as? [String] == strings)
            #expect(prepared.splitted.values[4] as? RawEncodedFixture == custom)
        }
    }

    @Test("R07 Injection-looking strings stay in bind values")
    func injectionLookingPayloadIsNotStructure() {
        let payload = #"O'Reilly\path' OR 1=1 --"#
        let unicodePayload = "café 雪"
        let raw: SQLRaw = "name = \(bind: payload)"
        let unicodeRaw: SQLRaw = "name = \(bind: unicodePayload), note = '雪'"

        for dialect in SQLDialect.all {
            let prepared = raw.prepare(dialect)
            let expectedQuery = dialect == .mysql ? "name = ?" : "name = $1"
            #expect(prepared.splitted.query == expectedQuery)
            #expect(prepared.splitted.values.count == 1)
            #expect(prepared.splitted.values[0] as? String == payload)

            let unicodePrepared = unicodeRaw.prepare(dialect)
            let expectedUnicodeQuery = dialect == .mysql
                ? "name = ?, note = '雪'"
                : "name = $1, note = '雪'"
            #expect(unicodePrepared.plain == "name = 'café 雪', note = '雪'")
            #expect(unicodePrepared.splitted.query == expectedUnicodeQuery)
            #expect(unicodePrepared.splitted.values.count == 1)
            #expect(unicodePrepared.splitted.values[0] as? String == unicodePayload)
            #expect(!unicodePrepared.splitted.query.contains(unicodePayload))
        }

        #expect(raw.prepare(.psql).plain == #"name = 'O'Reilly\path' OR 1=1 --'"#)
        #expect(raw.prepare(.mysql).plain == #"name = 'O'Reilly\path' OR 1=1 --'"#)
        #expect(raw.prepare(.duck).plain == #"name = 'O''Reilly\path'' OR 1=1 --'"#)
    }

    @Test("R08 Mixed raw bind output matches PostgreSQL, MySQL, and Duck")
    func exactMixedDialectOutput() {
        let id = 7
        let name = "Ada"
        let active = true
        let uuid = UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000")!
        let decimal = Decimal(string: "12.5")!
        let raw = SQL.raw(
            "SELECT * FROM users WHERE id = \(bind: id) AND name = \(bind: name) AND active = \(bind: active) AND token = \(bind: uuid) AND amount = \(bind: decimal)"
        )
        let expectedPlain = "SELECT * FROM users WHERE id = 7 AND name = 'Ada' AND active = TRUE AND token = '550E8400-E29B-41D4-A716-446655440000' AND amount = 12.5"
        let expectedPsql = "SELECT * FROM users WHERE id = $1 AND name = $2 AND active = $3 AND token = $4 AND amount = $5"
        let expectedMySQL = "SELECT * FROM users WHERE id = ? AND name = ? AND active = ? AND token = ? AND amount = ?"

        for dialect in SQLDialect.all {
            let prepared = raw.prepare(dialect)
            #expect(prepared.plain == expectedPlain)
            #expect(prepared.splitted.query == (dialect == .mysql ? expectedMySQL : expectedPsql))
            #expect(prepared.splitted.values.count == 5)
            #expect(prepared.splitted.values[0] as? Int == id)
            #expect(prepared.splitted.values[1] as? String == name)
            #expect(prepared.splitted.values[2] as? Bool == active)
            #expect(prepared.splitted.values[3] as? UUID == uuid)
            #expect(prepared.splitted.values[4] as? Decimal == decimal)
        }
    }

    @Test("R09 Empty and no-bind prepared views are identical")
    func emptyAndNoBindViewsMatch() {
        let empty: SQLRaw = ""
        let noBind: SQLRaw = "literal\nfragment  π"

        for dialect in SQLDialect.all {
            let emptyPrepared = empty.prepare(dialect)
            #expect(emptyPrepared.plain == "")
            #expect(emptyPrepared.splitted.query == "")
            #expect(emptyPrepared.splitted.values.isEmpty)

            let noBindPrepared = noBind.prepare(dialect)
            #expect(noBindPrepared.plain == "literal\nfragment  π")
            #expect(noBindPrepared.splitted.query == noBindPrepared.plain)
            #expect(noBindPrepared.splitted.values.isEmpty)
        }
    }

    @Test("R10 Typed then raw then typed values use one global order")
    func typedRawTypedOrdering() {
        let middle: SQLRaw = "raw=\(bind: 2)"
        let query = SQLableParts(
            parts: [SQLPartUnsafeValue(1), SQLPartOperator("|")]
                + middle.parts
                + [SQLPartOperator("|"), SQLPartUnsafeValue(3)]
        )
        let prepared = query.prepare(.psql).splitted

        #expect(prepared.query == "$1|raw=$2|$3")
        #expect(prepared.values.compactMap { $0 as? Int } == [1, 2, 3])
    }

    @Test("R11 Raw then typed then raw values use one global order")
    func rawTypedRawOrdering() {
        let first: SQLRaw = "first=\(bind: 10)"
        let last: SQLRaw = "last=\(bind: 30)"
        let query = SQLableParts(
            parts: first.parts
                + [SQLPartOperator("|"), SQLPartUnsafeValue(20), SQLPartOperator("|")]
                + last.parts
        )
        let prepared = query.prepare(.psql).splitted

        #expect(prepared.query == "first=$1|$2|last=$3")
        #expect(prepared.values.compactMap { $0 as? Int } == [10, 20, 30])
    }

    @Test("R12 Fragments compose in fluent, declarative, function, and nested contexts")
    func compositionContexts() {
        let table = DB.Table("events")
        let id = table.column("id")
        let raw: SQLRaw = "raw=\(bind: 12)"
        let fluent = SQL.select(raw).from(table)
        let declarative = SQL {
            Select(raw)
        }
        let function = Fn.coalesce(raw, 13)
        let nested = SQL.select(id).from(|SQL.select(raw).from(table)|)

        #expect(fluent.prepare(.psql).splitted.values.compactMap { $0 as? Int } == [12])
        #expect(declarative.prepare(.psql).splitted.values.compactMap { $0 as? Int } == [12])
        #expect(function.prepare(.psql).splitted.values.compactMap { $0 as? Int } == [12, 13])
        #expect(nested.prepare(.psql).splitted.values.compactMap { $0 as? Int } == [12])
        #expect(fluent.prepare(.psql).splitted.query.contains("$1"))
        #expect(declarative.prepare(.psql).splitted.query.contains("$1"))
        #expect(function.prepare(.psql).splitted.query.contains("$2"))
        #expect(nested.prepare(.psql).splitted.query.contains("$1"))
    }

    @Test("R13 Observation dispositions match raw bind collector order")
    func observationsFollowGlobalBindOrder() {
        let raw: SQLRaw = "raw=\(bind: 2)"
        let query = SQLableParts(
            parts: [SQLPartUnsafeValue(1), SQLPartOperator("|")]
                + raw.parts
                + [SQLPartOperator("|"), SQLPartUnsafeValue(3)]
        )
        let observed = query.prepareObservingUnsafeValues(.psql)
        let occurrences = completeOccurrences(observed)

        #expect(observed.prepared.splitted.query == "$1|raw=$2|$3")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [1, 2, 3])
        #expect(occurrences.compactMap { $0.value as? Int } == [1, 2, 3])
        #expect(occurrences.map(\.disposition) == [
            .bound(index: 0),
            .bound(index: 1),
            .bound(index: 2)
        ])
    }

    @Test("R14 Existing contextual inline policies apply only inside their owners")
    func contextualInliningRemainsOwnerSpecific() {
        let pattern = "metric%"
        let rawPattern: SQLRaw = "\(bind: pattern)"
        let direct = rawPattern.prepareObservingUnsafeValues(.duck)
        let star = SQLableParts(
            parts: SQLPartOperator("*", semanticRole: .starProjection)
        ).like(rawPattern).prepareObservingUnsafeValues(.duck)

        #expect(direct.prepared.splitted.query == "$1")
        #expect(direct.prepared.splitted.values.count == 1)
        #expect(completeOccurrences(direct).map(\.disposition) == [.bound(index: 0)])
        #expect(star.prepared.plain == "* LIKE 'metric%'")
        #expect(star.prepared.splitted.query == star.prepared.plain)
        #expect(star.prepared.splitted.values.isEmpty)
        #expect(completeOccurrences(star).map(\.disposition) == [.notBound])

        let payload = DB.Table("documents").column("payload")
        let fallback = 0
        let rawDefault: SQLRaw = "\(bind: fallback)"
        let jsonValue = JSONValue(payload, "$.p") {
            DefaultOnEmpty(rawDefault)
        }
        let psql = jsonValue.prepareObservingUnsafeValues(.psql)
        let mysql = jsonValue.prepareObservingUnsafeValues(.mysql)
        let duck = jsonValue.prepareObservingUnsafeValues(.duck)

        #expect(psql.prepared.splitted.query == #"JSON_VALUE("documents"."payload", $1 DEFAULT 0 ON EMPTY)"#)
        #expect(mysql.prepared.splitted.query == "JSON_VALUE(documents.payload, ? DEFAULT 0 ON EMPTY)")
        #expect(duck.prepared.splitted.query == #"JSON_VALUE("documents"."payload", $1 DEFAULT $2 ON EMPTY)"#)
        #expect(psql.prepared.splitted.values.count == 1)
        #expect(mysql.prepared.splitted.values.count == 1)
        #expect(duck.prepared.splitted.values.count == 2)
        #expect(completeOccurrences(psql).map(\.disposition) == [.bound(index: 0), .notBound])
        #expect(completeOccurrences(mysql).map(\.disposition) == [.bound(index: 0), .notBound])
        #expect(completeOccurrences(duck).map(\.disposition) == [.bound(index: 0), .bound(index: 1)])
    }

    @Test("R15 Default marker text survives around real binds")
    func defaultMarkerTextCollision() {
        let markerText = "§§§lead §prefix mid§suffix §§ tail§§§ lone § adjacent §§ exact §§§ prefix§§§ suffix§§§"
        let raw: SQLRaw = "left \(bind: 1) §§§lead §prefix mid§suffix §§ tail§§§ lone § adjacent §§ exact §§§ prefix§§§ suffix§§§ \(bind: 2) right"

        for dialect in SQLDialect.all {
            let prepared = raw.prepare(dialect)
            let firstKey = dialect == .mysql ? "?" : "$1"
            let secondKey = dialect == .mysql ? "?" : "$2"
            #expect(prepared.plain == "left 1 \(markerText) 2 right")
            #expect(prepared.splitted.query == "left \(firstKey) \(markerText) \(secondKey) right")
            #expect(prepared.splitted.values.compactMap { $0 as? Int } == [1, 2])
        }
    }

    @Test("R16 Custom marker spelling cannot consume caller text")
    func customMarkerTextCollision() {
        let markerText = "%%%lead %prefix middle%suffix %% tail %%%"
        let raw: SQLRaw = "left \(bind: 5) %%%lead %prefix middle%suffix %% tail %%% right"
        let dialect = DistinctRawMarkerDialect()
        let prepared = raw.prepare(dialect)

        #expect(prepared.plain == "left 5 \(markerText) right")
        #expect(prepared.splitted.query == "left @raw1 \(markerText) right")
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? Int == 5)
    }

    @Test("R17 Legacy String raw and String.raw calls remain caller-owned text")
    func legacyRawStringRoutes() {
        let value = 7
        let literal = SQL.raw("value = \(value)")
        let source: String = "value = 7"
        let variable = SQL.raw(source)
        let stringRaw = "value = 7".raw
        let legacyComposition = SQL.select("trusted").raw("WHERE id = 7")

        #expect(literal.prepare(.psql).plain == "value = 7")
        #expect(literal.prepare(.psql).splitted.values.isEmpty)
        #expect(variable.prepare(.psql).plain == "value = 7")
        #expect(variable.prepare(.psql).splitted.values.isEmpty)
        #expect(stringRaw.prepare(.psql).plain == "value = 7")
        #expect(stringRaw.prepare(.psql).splitted.values.isEmpty)

        let psqlComposition = legacyComposition.prepare(.psql).splitted
        let mysqlComposition = legacyComposition.prepare(.mysql).splitted
        #expect(psqlComposition.query == "SELECT $1 WHERE id = 7")
        #expect(mysqlComposition.query == "SELECT ? WHERE id = 7")
        #expect(psqlComposition.values.count == 1)
        #expect(mysqlComposition.values.count == 1)
        #expect(psqlComposition.values[0] as? String == "trusted")
        #expect(mysqlComposition.values[0] as? String == "trusted")
    }

    @Test("R18 Legacy String raw spacing remains unchanged")
    func legacyRawStringSpacing() {
        let base = SQLableParts(parts: SQLPartOperator("BASE"))
        let spacedBase = SQLableParts(parts: [SQLPartOperator("BASE"), .space])

        #expect(SQL.raw("TAIL").prepare(.psql).plain == "TAIL")
        #expect(base.raw("TAIL").prepare(.psql).plain == "BASE TAIL")
        #expect(spacedBase.raw("TAIL").prepare(.psql).plain == "BASE TAIL")
        #expect(SQLableParts.raw("TAIL").prepare(.psql).plain == " TAIL")
        #expect("TAIL".raw.prepare(.psql).plain == "TAIL")
    }

    @Test("R19 SQLRaw raw overloads match String raw spacing")
    func rawCarrierSpacingMatchesLegacyRoutes() {
        let base = SQLableParts(parts: SQLPartOperator("BASE"))
        let spacedBase = SQLableParts(parts: [SQLPartOperator("BASE"), .space])
        let carrier: SQLRaw = "TAIL"

        #expect(SQL.raw(carrier).prepare(.psql).plain == "TAIL")
        #expect(base.raw(carrier).prepare(.psql).plain == "BASE TAIL")
        #expect(spacedBase.raw(carrier).prepare(.psql).plain == "BASE TAIL")
        #expect(SQLableParts.raw(carrier).prepare(.psql).plain == " TAIL")
    }

    @Test("R20 Interpolation expressions evaluate once across prepared views")
    func interpolationExpressionEvaluatesOnce() {
        var evaluationCount = 0
        func nextValue() -> Int {
            evaluationCount += 1
            return evaluationCount
        }

        let raw: SQLRaw = "value=\(bind: nextValue())"
        #expect(evaluationCount == 1)

        let prepared = raw.prepare(.psql)
        #expect(prepared.plain == "value=1")
        #expect(prepared.splitted.query == "value=$1")
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? Int == 1)
        #expect(evaluationCount == 1)
    }
}
