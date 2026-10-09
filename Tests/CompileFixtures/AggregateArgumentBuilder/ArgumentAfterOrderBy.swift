import SQL

let expression = Fn.aggregate(.custom("bad_after_order")) {
    Path.Column("value")
    OrderBy(Path.Column("value"), .asc)
    Path.Column("late")
}

_ = expression
