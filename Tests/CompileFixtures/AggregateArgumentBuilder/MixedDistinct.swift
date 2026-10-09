import SQL

let expression = Fn.aggregate(.custom("bad_mixed_distinct")) {
    Path.Column("value")
    Distinct(Path.Column("other"))
}

_ = expression
