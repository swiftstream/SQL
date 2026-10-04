//
//  UpdateTableBuilder.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

public class UpdateTableBuilder<T: Table>: SQLable {
    public var parts: [SQLPart] {
        let table = Path.Schema(schemaName).table(T.tableName)
        var parts: [SQLPart] = []
        if combinedAlterActions.count > 0 {
            var combinedParts = SQL.root.alter.table[any: table].parts
            combinedParts.append(o: .space)
            combinedAlterActions.enumerated().forEach { i, action in
                if i > 0 {
                    combinedParts.append(o: .comma)
                    combinedParts.append(o: .space)
                }
                combinedParts.append(contentsOf: action)
            }
            combinedParts.append(o: .semicolon)
            parts.append(contentsOf: combinedParts)
        }
        standAloneAlterActions.forEach { action in
            var standAloneParts = SQL.root.alter.table[any: table].parts
            standAloneParts.append(o: .space)
            standAloneParts.append(contentsOf: action)
            standAloneParts.append(o: .semicolon)
            parts.append(contentsOf: standAloneParts)
        }
        otherActions.forEach { action in
            var actionParts = action
            actionParts.append(o: .semicolon)
            parts.append(contentsOf: actionParts)
        }
        if let newName = renameTableTo {
            var renameParts = SQL.root.alter.table[any: table].parts
            renameParts.append(o: .space)
            renameParts.append(o: .rename)
            renameParts.append(o: .space)
            renameParts.append(o: .to)
            renameParts.append(o: .space)
            renameParts.append(SQLPartColumn(newName))
            renameParts.append(o: .semicolon)
            parts.append(contentsOf: renameParts)
        }
        return parts
    }
    
    var combinedAlterActions: [[SQLPart]] = []
    var standAloneAlterActions: [[SQLPart]] = []
    var otherActions: [[SQLPart]] = []
    var renameTableTo: String?
    var schemaName: String?
    
    public init (schema: Schemable.Type? = nil) {
        self.schemaName = schema?.schemaName ?? (T.self as? Schemable.Type)?.schemaName
    }
    
    public init (schema: String) {
        self.schemaName = schema
    }
    
    // MARK: - RENAME TABLE
    
    /// For changing the table name.
    public func renameTable(to: String) -> Self {
        renameTableTo = to
        return self
    }
    
    // MARK: - ADD COLUMN
    
    public func addColumn(_ newColumn: NewColumn) -> Self {
        var parts: [SQLPart] = []
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(contentsOf: newColumn.parts)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: KeyPath
    
    /// Adds a new column to a table.
    public func addColumn<V>(_ keyPath: KeyPath<T, V>, _ type: Type, checkIfNotExists: Bool = false) -> Self where V: ColumnRepresentable {
        addColumn(keyPath, type: type, default: nil, checkIfNotExists: checkIfNotExists, constraints: [])
    }
    
    /// Adds a new column to a table.
    public func addColumn<V>(_ keyPath: KeyPath<T, V>, _ type: Type, checkIfNotExists: Bool = false, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        addColumn(keyPath, type: type, default: nil, checkIfNotExists: checkIfNotExists, constraints: constraints)
    }
    
    /// Adds a new column to a table.
    public func addColumn<V>(_ keyPath: KeyPath<T, V>, _ type: Type, _ `default`: ColumnDefault, checkIfNotExists: Bool = false, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        addColumn(keyPath, type: type, default: `default`, checkIfNotExists: checkIfNotExists, constraints: constraints)
    }
    
    /// Adds a new column to a table.
    public func addColumn<V>(_ keyPath: KeyPath<T, V>, type: Type, `default`: ColumnDefault?, checkIfNotExists: Bool = false, constraints: [Constraint]) -> Self where V: ColumnRepresentable {
        addColumn(T.key(for: keyPath), type: type, default: `default`, checkIfNotExists: checkIfNotExists, constraints: constraints)
    }
    
    // MARK: String
    
    /// Adds a new column to a table.
    public func addColumn(_ name: String, _ type: Type, checkIfNotExists: Bool = false) -> Self {
        addColumn(name, type: type, default: nil, checkIfNotExists: checkIfNotExists, constraints: [])
    }
    
    /// Adds a new column to a table.
    public func addColumn(_ name: String, _ type: Type, checkIfNotExists: Bool = false, _ constraints: Constraint...) -> Self {
        addColumn(name, type: type, default: nil, checkIfNotExists: checkIfNotExists, constraints: constraints)
    }
    
    /// Adds a new column to a table.
    public func addColumn(_ name: String, _ type: Type, _ `default`: ColumnDefault, checkIfNotExists: Bool = false, _ constraints: Constraint...) -> Self {
        addColumn(name, type: type, default: `default`, checkIfNotExists: checkIfNotExists, constraints: constraints)
    }
    
    /// Adds a new column to a table.
    public func addColumn(_ name: String, type: Type, `default`: ColumnDefault?, checkIfNotExists: Bool = false, constraints: [Constraint]) -> Self {
        var parts: [SQLPart] = []
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .column)
        if checkIfNotExists {
            parts.append(o: .space)
            parts.append(o: .if)
            parts.append(o: .space)
            parts.append(o: .not)
            parts.append(o: .space)
            parts.append(o: .exists)
        }
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(SQLPartType(type))
        if let expression = `default` {
            parts.append(o: .space)
            parts.append(contentsOf: expression.query.parts)
        }
        constraints.forEach { expression in
            parts.append(o: .space)
            parts.append(contentsOf: expression.query.parts)
        }
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - DROP COLUMN
    
    /// For dropping a table column.
    /// The constraints and indexes imposed on the columns will also be dropped.
    ///
    /// You should use "string" table names instead of KeyPaths to keep consistency with previous migrations.
    ///
    /// Usage:
    ///
    /// ```swift
    /// .dropColumn(\User.$name)
    /// .dropColumn(\User.$surname, checkIfExists: true) // default `false`
    /// .dropColumn(\User.$createdAt, cascade: true) // default `false`
    /// ```
    public func dropColumn<V>(_ keyPath: KeyPath<T, V>, checkIfExists: Bool = false, cascade: Bool = false)  -> Self where V: ColumnRepresentable {
        dropColumn(T.key(for: keyPath), checkIfExists: checkIfExists, cascade: cascade)
    }
    
    /// For dropping a table column.
    /// The constraints and indexes imposed on the columns will also be dropped.
    ///
    /// Usage:
    ///
    /// ```swift
    /// .dropColumn("abc")
    /// .dropColumn("xyz", checkIfExists: true) // default `false`
    /// .dropColumn("qwe", cascade: true) // default `false`
    /// ```
    public func dropColumn(_ name: String, checkIfExists: Bool = false, cascade: Bool = false) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .drop)
        parts.append(o: .space)
        parts.append(o: .column)
        if checkIfExists {
            parts.append(o: .space)
            parts.append(o: .if)
            parts.append(o: .space)
            parts.append(o: .exists)
        }
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        if cascade {
            parts.append(o: .space)
            parts.append(o: .cascade)
        }
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - SET DEFAULT
    
    /// Use for adding/changing the default value for a column.
    public func setDefault<V>(_ keyPath: KeyPath<T, V>, constant v: Any)  -> Self where V: ColumnRepresentable {
        setDefault(T.key(for: keyPath), constant: v)
    }
    
    /// Use for adding/changing the default value for a column.
    public func setDefault<V>(_ keyPath: KeyPath<T, V>, expression: SQLable)  -> Self where V: ColumnRepresentable {
        setDefault(T.key(for: keyPath), expression: expression)
    }
    
    /// Use for adding/changing the default value for a column.
    public func setDefault<V>(_ keyPath: KeyPath<T, V>, sequence name: String)  -> Self where V: ColumnRepresentable {
        setDefault(T.key(for: keyPath), sequence: name)
    }
    
    /// Use for adding/changing the default value for a column.
    public func setDefault(_ name: String, constant v: Any) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(o: .default)
        parts.append(o: .space)
        parts.append(SQLPartSafeValue(v))
        combinedAlterActions.append(parts)
        return self
    }
    
    /// Use for adding/changing the default value for a column.
    public func setDefault(_ name: String, expression: SQLable) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(o: .default)
        parts.append(o: .space)
        parts.append(contentsOf: expression.parts)
        combinedAlterActions.append(parts)
        return self
    }
    
    /// Use for adding/changing the default value for a column.
    public func setDefault(_ name: String, sequence: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(o: .default)
        parts.append(o: .space)
        parts.append(Op.custom(sequence))
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - DROP DEFAULT
    
    /// Use for removing the default value for a column.
    public func dropDefault<V>(_ keyPath: KeyPath<T, V>)  -> Self where V: ColumnRepresentable {
        dropDefault(T.key(for: keyPath))
    }
    
    /// Use for removing the default value for a column.
    public func dropDefault(_ name: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .drop)
        parts.append(o: .space)
        parts.append(o: .default)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - SET NOT NULL
    
    /// Use for removing NOT NULL mark for a column.
    public func setNotNull<V>(_ keyPath: KeyPath<T, V>)  -> Self where V: ColumnRepresentable {
        setNotNull(T.key(for: keyPath))
    }
    
    /// Use for removing NOT NULL mark for a column.
    public func setNotNull(_ name: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(o: .not)
        parts.append(o: .space)
        parts.append(o: .null)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - DROP NOT NULL
    
    /// Use for removing NOT NULL mark for a column.
    public func dropNotNull<V>(_ keyPath: KeyPath<T, V>)  -> Self where V: ColumnRepresentable {
        dropNotNull(T.key(for: keyPath))
    }
    
    /// Use for removing NOT NULL mark for a column.
    public func dropNotNull(_ name: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .alter)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .drop)
        parts.append(o: .space)
        parts.append(o: .not)
        parts.append(o: .space)
        parts.append(o: .null)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - RENAME COLUMN
    
    /// For changing the table name or a column name.
    public func renameColumn<V>(_ keyPath: KeyPath<T, V>, to: String)  -> Self where V: ColumnRepresentable {
        renameColumn(T.key(for: keyPath), to: to)
    }
    
    /// For changing the table name or a column name.
    public func renameColumn(_ name: String, to: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .rename)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(o: .to)
        parts.append(o: .space)
        parts.append(SQLPartColumn(to))
        standAloneAlterActions.append(parts)
        return self
    }
    
    // MARK: - DROP CONSTRAINT
    
    /// Use for dropping a table constraint.
    public func dropConstraint(_ name: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .drop)
        parts.append(o: .space)
        parts.append(o: .constraint)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        otherActions.append(parts)
        return self
    }
    
    // MARK: - ADD UNIQUE
    
    /// Use to add UNIQUE mark to one or several columns.
    public func addUnique(to columns: String...) -> Self {
        guard columns.count > 0 else { return self }
        var parts = SQL.root.parts
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .unique)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        columns.enumerated().forEach { i, name in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SQLPartColumn(name))
        }
        parts.append(o: .closeBracket)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - ADD PRIMARY KEY
    
    /// Use to add PRIMARY KEY mark to one or several columns.
    public func addPrimaryKey(to columns: String...) -> Self {
        guard columns.count > 0 else { return self }
        var parts = SQL.root.parts
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .primary)
        parts.append(o: .space)
        parts.append(o: .key)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        columns.enumerated().forEach { i, name in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SQLPartColumn(name))
        }
        parts.append(o: .closeBracket)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - DROP INDEX
    
    /// Drops index by its name.
    public func dropIndex(schema: String? = nil, name: String) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .drop)
        parts.append(o: .space)
        parts.append(o: .index)
        parts.append(o: .space)
        if let schema = schema {
            parts.append(SQLPartColumn(schema))
            parts.append(o: .period)
        }
        parts.append(SQLPartColumn(name))
        otherActions.append(parts)
        return self
    }
    
    // MARK: - CREATE INDEX
    
    /// Creates index for one or several columns.
    public func createIndex(unique: Bool = false, name: String? = nil, items: IndexItem..., type: IndexType? = nil, where condition: SQLable? = nil) -> Self {
        createIndex(unique: unique, name: name, items: items, type: type, where: condition)
    }
    
    /// Creates index for one or several columns.
    public func createIndex(unique: Bool = false, name: String? = nil, items: [IndexItem], type: IndexType? = nil, where condition: SQLable? = nil) -> Self {
        guard items.count > 0 else { return self }
        var parts = SQL.root.parts
        parts.append(o: .create)
        if unique {
            parts.append(o: .space)
            parts.append(o: .unique)
        }
        parts.append(o: .space)
        parts.append(o: .index)
        if let name = name {
            parts.append(o: .space)
            parts.append(SQLPartColumn(name))
        }
        parts.append(o: .space)
        parts.append(o: .on)
        parts.append(o: .space)
        parts.append(contentsOf: Path.Schema(schemaName).table(T.tableName).parts)
        if let type = type {
            parts.append(o: .space)
            parts.append(o: .using)
            parts.append(o: .space)
            parts.append(contentsOf: type.parts)
            parts.append(o: .space)
        }
        parts.append(o: .openBracket)
        items.enumerated().forEach { i, item in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: item.parts)
        }
        parts.append(o: .closeBracket)
        if let condition = condition {
            parts.append(o: .space)
            parts.append(o: .where)
            parts.append(o: .space)
            parts.append(contentsOf: condition.parts)
        }
        otherActions.append(parts)
        return self
    }
    
    // MARK: - ADD CHECK
    
    /// A check constraint helps in validating the records that are being inserted into a table.
    /// We can do this by combining the ALTER TABLE command with the ADD CHECK statement.
    public func addCheck(constraintName: String? = nil, _ expression: SQLable) -> Self {
        var parts = SQL.root.parts
        parts.append(o: .add)
        if let constraintName = constraintName {
            parts.append(o: .space)
            parts.append(o: .constraint)
            parts.append(o: .space)
            parts.append(SQLPartColumn(constraintName))
        }
        parts.append(o: .space)
        parts.append(o: .check)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: expression.parts)
        parts.append(o: .closeBracket)
        combinedAlterActions.append(parts)
        return self
    }
    
    // MARK: - ADD FOREIGN KEY
    
    public func addForeignKey(column: String, constraintName: String? = nil, schema: String? = nil, table: String, columns: String..., onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Self {
        addForeignKey(column: column, constraintName: constraintName, schema: schema, table: table, columns: columns, onDelete: onDelete, onUpdate: onUpdate)
    }
    
    public func addForeignKey(column: String, constraintName: String? = nil, schema: String? = nil, table: String, columns: [String], onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Self {
        guard columns.count > 0 else { return self }
        var parts = SQL.root.parts
        parts.append(o: .add)
        if let constraintName = constraintName {
            parts.append(o: .space)
            parts.append(o: .constraint)
            parts.append(o: .space)
            parts.append(SQLPartColumn(constraintName))
        }
        parts.append(o: .space)
        parts.append(o: .foreign)
        parts.append(o: .space)
        parts.append(o: .key)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(SQLPartColumn(column))
        parts.append(o: .closeBracket)
        parts.append(o: .space)
        parts.append(o: .references)
        parts.append(o: .space)
        parts.append(SQLPartTable(schema: schema, table: table))
        parts.append(o: .openBracket)
        columns.enumerated().forEach { i, name in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SQLPartColumn(name))
        }
        parts.append(o: .closeBracket)
        if let action = onDelete {
            parts.append(o: .space)
            parts.append(o: .on)
            parts.append(o: .space)
            parts.append(o: .delete)
            parts.append(o: .space)
            parts.append(contentsOf: action.parts)
        }
        if let action = onUpdate {
            parts.append(o: .space)
            parts.append(o: .on)
            parts.append(o: .space)
            parts.append(o: .update)
            parts.append(o: .space)
            parts.append(contentsOf: action.parts)
        }
        combinedAlterActions.append(parts)
        return self
    }
    
    // TODO: https://www.postgresql.org/docs/current/sql-altertable.html
    
    // MARK: - SET STATISTICS
    
    /// For setting the statistics-gathering target for each column for ANALYZE operations.
    
    // MARK: - SET STORAGE
    
    /// For setting the mode of storage for a column.
    /// This will determine where the column is held, whether inline, or in a supplementary table.
    
    // MARK: - SET WITHOUT OIDS
    
    /// Use for removing the old column of the table.
    
    // MARK: - OWNER
    
    /// For changing the owner of a table, sequence, index or a view to a certain user.
    
    // MARK: - CLUSTER
    
    /// For marking a table to be used for carrying out future cluster operations.
}
