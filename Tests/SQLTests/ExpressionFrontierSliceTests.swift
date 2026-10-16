@testable import SQL
import Testing

@Suite("Expression Frontier Slice Tests")
struct ExpressionFrontierSliceTests: SwifQLTests {
    private final class CountingSQLable: SQLable {
        private let value: any SQLable
        private(set) var reads = 0

        init(_ value: any SQLable) {
            self.value = value
        }

        var parts: [SQLPart] {
            reads += 1
            return value.parts
        }
    }

    @Test("Slice forms render exact bracket interiors")
    func exactForms() {
        let scores = DB.Column("scores")

        check(
            scores[slice(2, 4)],
            .psql(#""scores"[2:4]"#),
            .mysql("scores[2:4]"),
            .duck(#""scores"[2:4]"#)
        )

        check(
            scores[slice(through: 4)],
            .psql(#""scores"[:4]"#),
            .mysql("scores[:4]"),
            .duck(#""scores"[:4]"#)
        )

        check(
            scores[slice(from: 2)],
            .psql(#""scores"[2:]"#),
            .mysql("scores[2:]"),
            .duck(#""scores"[2:]"#)
        )

        check(
            scores[slice()],
            .psql(#""scores"[:]"#),
            .mysql("scores[:]"),
            .duck(#""scores"[:]"#)
        )
    }

    @Test("Duck stepped slice keeps exact SQL identity")
    func steppedSlice() {
        let scores = DB.Column("scores")
        let expression = scores[slice(2, 8, step: 2)]

        #expect(expression.prepare(.duck).plain == #""scores"[2:8:2]"#)
        #expect(expression.prepare(.psql).plain == #""scores"[2:8:2]"#)
        #expect(expression.prepare(.mysql).plain == "scores[2:8:2]")
    }

    @Test("Slice reuses Wave 04 general-expression base grouping")
    func generalExpressionBase() {
        let expression = Fn.arrayAgg(DB.Column("score"))[slice(2, 4)]

        #expect(expression.prepare(.psql).plain == #"(array_agg("score"))[2:4]"#)
        #expect(expression.prepare(.psql).splitted.query == #"(array_agg("score"))[$1:$2]"#)
        #expect(expression.prepare(.duck).plain == #"array_agg("score")[2:4]"#)
        #expect(expression.prepare(.mysql).plain == "array_agg(score)[2:4]")
    }

    @Test("Slice composes with chained index subscripts")
    func chainedSubscripts() {
        let scores = DB.Column("scores")

        let sliceThenIndex = scores[slice(2, 4)][1]
        #expect(sliceThenIndex.prepare(.psql).plain == #""scores"[2:4][1]"#)
        #expect(sliceThenIndex.prepare(.duck).plain == #""scores"[2:4][1]"#)
        #expect(sliceThenIndex.prepare(.mysql).plain == "scores[2:4][1]")

        let indexThenSlice = scores[1][slice(2, 4)]
        #expect(indexThenSlice.prepare(.psql).plain == #""scores"[1][2:4]"#)
        #expect(indexThenSlice.prepare(.duck).plain == #""scores"[1][2:4]"#)
        #expect(indexThenSlice.prepare(.mysql).plain == "scores[1][2:4]")
    }

    @Test("Slice preserves lower upper step bind order")
    func bindOrder() {
        let expression = DB.Column("scores")[slice(2, 8, step: 3)]

        let postgres = expression.prepare(.psql)
        #expect(postgres.splitted.query == #""scores"[$1:$2:$3]"#)
        #expect(postgres.splitted.values.count == 3)
        #expect(postgres.splitted.values[0] as? Int == 2)
        #expect(postgres.splitted.values[1] as? Int == 8)
        #expect(postgres.splitted.values[2] as? Int == 3)

        let duck = expression.prepare(.duck)
        #expect(duck.splitted.query == #""scores"[$1:$2:$3]"#)
        #expect(duck.splitted.values.count == 3)

        let mysql = expression.prepare(.mysql)
        #expect(mysql.splitted.query == "scores[?:?:?]")
        #expect(mysql.splitted.values.count == 3)
    }

    @Test("Slice snapshots every bound exactly once")
    func singleEvaluation() {
        let lower = CountingSQLable(2)
        let upper = CountingSQLable(8)
        let step = CountingSQLable(3)

        let operand = slice(lower, upper, step: step)
        let expression = DB.Column("scores")[operand]

        _ = expression.prepare(.psql)
        _ = expression.prepare(.duck)

        #expect(lower.reads == 1)
        #expect(upper.reads == 1)
        #expect(step.reads == 1)
    }

    @Test("Slice accepts negative ordinary expression bounds")
    func negativeBounds() {
        let expression = DB.Column("scores")[slice(-4, -1)]

        #expect(expression.prepare(.psql).plain == #""scores"[-4:-1]"#)
        #expect(expression.prepare(.duck).plain == #""scores"[-4:-1]"#)
        #expect(expression.prepare(.mysql).plain == "scores[-4:-1]")
    }

    @Test("Slice composes with exact SQLArray bases")
    func sqlArrayBase() {
        let expression = SQLArray.items(10, 20, 30)[slice(1, 2)]

        #expect(expression.prepare(.psql).plain == "(ARRAY[10, 20, 30])[1:2]")
        #expect(expression.prepare(.duck).plain == "ARRAY[10, 20, 30][1:2]")
        #expect(expression.prepare(.mysql).plain == "ARRAY[10, 20, 30][1:2]")
    }

    @Test("Lowercase SQL slice does not disturb Swift slice types")
    func swiftSliceCoexistence() {
        let arraySlice: ArraySlice<Int> = [1, 2, 3][0..<2]
        let standardSliceType: Slice<UnsafeBufferPointer<Int>>.Type =
            Slice<UnsafeBufferPointer<Int>>.self
        let closedRange = 1...2
        let partialRange = 2...

        #expect(arraySlice == [1, 2])
        #expect(closedRange.count == 2)
        #expect(partialRange.lowerBound == 2)
        _ = standardSliceType
    }
}
