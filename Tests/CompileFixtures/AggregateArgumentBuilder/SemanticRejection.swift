import SQL

let mode = CommandLine.arguments.dropFirst().first ?? "positive"

switch mode {
case "positive":
    let plain = Fn.aggregate(.custom("ok_plain_distinct")) {
        Distinct {
            Path.Column("value")
        }
    }
    precondition(
        plain.prepare(.psql).plain
            == #"ok_plain_distinct(DISTINCT "value")"#
    )

    let empty = Fn.aggregate(.custom("ok_empty")) {}
    precondition(empty.prepare(.psql).plain == "ok_empty()")

    let selectDistinctOn = Distinct(on: Path.Column("value"))
    precondition(
        selectDistinctOn.prepare(.psql).plain
            == #"DISTINCT ON ("value")"#
    )

    print("EF01_WAVE_D_SEMANTIC_POSITIVE: PASS")

case "distinct-on":
    _ = Fn.aggregate(.custom("bad_distinct_on")) {
        Distinct(on: Path.Column("value"))
    }.parts

case "empty-distinct":
    _ = Fn.aggregate(.custom("bad_empty_distinct")) {
        Distinct {}
    }.parts

case "dynamic-empty":
    let includeValue = false
    _ = Fn.aggregate(.custom("bad_dynamic_empty_distinct")) {
        Distinct {
            if includeValue {
                Path.Column("value")
            }
        }
    }.parts

default:
    fatalError("Unknown mode: \(mode)")
}
