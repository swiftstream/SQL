import SQL

let expression = Fn.aggregate(.custom("bad_distinct_order")) {
    Distinct {
        Path.Column("value")
        OrderBy(Path.Column("value"), .desc)
    }
}

_ = expression
