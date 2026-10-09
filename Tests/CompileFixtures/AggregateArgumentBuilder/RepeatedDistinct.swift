import SQL

let expression = Fn.aggregate(.custom("bad_repeated_distinct")) {
    Distinct(Path.Column("first"))
    Distinct(Path.Column("second"))
}

_ = expression
