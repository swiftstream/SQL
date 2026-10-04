//
//  Type.swift
//  SwifQL
//
//  Created by Mihael Isaev on 12/10/2019.
//

public struct TypeConstructor: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let list = Self(namespace: "swifql", name: "list")
    public static let array = Self(namespace: "swifql", name: "array")
    public static let map = Self(namespace: "swifql", name: "map")
    public static let `struct` = Self(namespace: "swifql", name: "struct")
    public static let union = Self(namespace: "swifql", name: "union")
}

public struct TypeMember: Equatable, Sendable {
    public let name: String
    public let type: Type

    public init(_ name: String, _ type: Type) {
        self.name = name
        self.type = type
    }
}

public indirect enum TypeStructure: Equatable, Sendable {
    case collection(TypeConstructor, element: Type, length: Int?)
    case map(TypeConstructor, key: Type, value: Type)
    case members(TypeConstructor, [TypeMember])
}

typealias CastType = Type

public struct Type: Equatable, Sendable {
    let name: String
    public let structure: TypeStructure?
    
    public init (_ name: String) {
        self.name = name
        self.structure = nil
    }

    public init(structure: TypeStructure) {
        self.name = structure.legacyName
        self.structure = structure
    }

    /// The structured form, when this value was created by a nested type
    /// constructor. Raw and scalar `Type(String)` values remain unstructured.
    public var structuredRepresentation: TypeStructure? {
        structure
    }
    
    // MARK: -
    
    /// enum
    public static let `enum`: Type = .init("ENUM")
    
    /// range
    public static let range: Type = .init("RANGE")
    
    
    // MARK: -
    // MARK: Numeric Types
    
    /// signed two-byte integer
    public static let smallint: Type = .init("smallint")
    public static let smallintArray: Type = .init("smallint[]")
    
    /// signed four-byte integer
    public static let int4: Type = .init("int4")
    public static let int4Array: Type = .init("int4[]")
    
    /// signed two-byte integer
    public static let int2: Type = .init("int2")
    public static let int2Array: Type = .init("int2[]")
    
    /// signed eight-byte integer
    public static let int8: Type = .init("int8")
    public static let int8Array: Type = .init("int8[]")
    
    /// signed four-byte integer
    public static let int: Type = .init("int")
    public static let intArray: Type = .init("int[]")
    
    /// signed four-byte integer
    public static let integer: Type = .init("integer")
    public static let integerArray: Type = .init("integer[]")
    
    /// signed eight-byte integer
    public static let bigint: Type = .init("bigint")
    public static let bigintArray: Type = .init("bigint[]")

    /// signed one-byte integer
    public static let tinyint: Type = .init("tinyint")

    /// signed sixteen-byte integer
    public static let hugeint: Type = .init("hugeint")

    /// unsigned one-byte integer
    public static let utinyint: Type = .init("utinyint")

    /// unsigned two-byte integer
    public static let usmallint: Type = .init("usmallint")

    /// unsigned four-byte integer
    public static let uinteger: Type = .init("uinteger")

    /// unsigned eight-byte integer
    public static let ubigint: Type = .init("ubigint")

    /// unsigned sixteen-byte integer
    public static let uhugeint: Type = .init("uhugeint")
    
    /// exact numeric of selectable precision
    public static let decimal: Type = .init("decimal")
    public static let decimalArray: Type = .init("decimal[]")
    /// exact numeric of selectable precision
    public static func decimal(_ p: Int, _ s: Int) -> Type { .init("decimal(\(p), \(s))") }
    
    /// exact numeric of selectable precision
    public static let numeric: Type = .init("numeric")
    public static let numericArray: Type = .init("numeric[]")
    /// exact numeric of selectable precision
    public static func numeric(_ p: Int, _ s: Int) -> Type { .init("numeric(\(p), \(s))") }
    
    /// single precision floating-point number (4 bytes)
    public static let real: Type = .init("real")
    public static let realArray: Type = .init("real[]")
    
    public static func float(_ v: Int) -> Type { .init("float(\(v))") }
    
    /// single precision floating-point number (4 bytes)
    public static let float4: Type = .init("float4")
    public static let float4Array: Type = .init("float4[]")
    
    /// double precision floating-point number (8 bytes)
    public static let float8: Type = .init("float8")
    public static let float8Array: Type = .init("float8[]")
    
    /// double precision floating-point number (8 bytes)
    public static let doublePrecision: Type = .init("double precision")
    public static let doublePrecisionArray: Type = .init("double precision[]")
    
    /// autoincrementing two-byte integer
    public static let smallserial: Type = .init("smallserial")
    public static let smallserialArray: Type = .init("smallserial[]")
    
    /// autoincrementing two-byte integer
    public static let serial2: Type = .init("serial2")
    public static let serial2Array: Type = .init("serial2[]")
    
    /// autoincrementing four-byte integer
    public static let serial: Type = .init("serial")
    public static let serialArray: Type = .init("serial[]")
    
    /// autoincrementing four-byte integer
    public static let serial4: Type = .init("serial4")
    public static let serial4Array: Type = .init("serial4[]")
    
    /// autoincrementing eight-byte integer
    public static let serial8: Type = .init("serial8")
    public static let serial8Array: Type = .init("serial8[]")
    
    /// autoincrementing eight-byte integer
    public static let bigserial: Type = .init("bigserial")
    public static let bigserialArray: Type = .init("bigserial[]")
    
    // MARK: Monetary Types
    
    /// currency amount
    public static let money: Type = .init("money")
    public static let moneyArray: Type = .init("money[]")
    
    // MARK: Character Types
    
    /// fixed-length character string
    public static let char: Type = .init("char")
    public static let charArray: Type = .init("char[]")
    
    /// variable-length character string
    public static let varchar: Type = .init("varchar")
    public static func varchar(_ n: Int) -> Type { .init("varchar(\(n))") }
    public static let varcharArray: Type = .init("varchar[]")
    
    /// variable-length character string
    public static let text: Type = .init("text")
    public static let textArray: Type = .init("text[]")
    
    // MARK: Binary Data Types
    
    /// binary data (“byte array”)
    public static let bytea: Type = .init("bytea")
    public static let byteaArray: Type = .init("bytea[]")

    /// binary data
    public static let blob: Type = .init("blob")
    
    // MARK: Date/Time Types
    
    /// date and time (no time zone)
    public static let timestamp: Type = .init("timestamp")
    public static let timestampArray: Type = .init("timestamp[]")
    
    /// date and time (no time zone)
    public static let timestampWithoutTimeZone: Type = .init("timestamp without time zone")
    public static let timestampWithoutTimeZoneArray: Type = .init("timestamp without time zone[]")
    
    /// date and time, including time zone
    public static let timestampWithTimeZone: Type = .init("timestamp with time zone")
    public static let timestampWithTimeZoneArray: Type = .init("timestamp with time zone[]")
    
    /// date and time, including time zone
    public static let timestamptz: Type = .init("timestamptz")
    public static let timestamptzArray: Type = .init("timestamptz[]")

    /// date and time with seconds precision
    public static let timestampS: Type = .init("timestamp_s")

    /// date and time with milliseconds precision
    public static let timestampMs: Type = .init("timestamp_ms")

    /// date and time with nanoseconds precision
    public static let timestampNs: Type = .init("timestamp_ns")
    
    /// date and time
    public static func timestamp(_ p: Int, withTimeZone: Bool = false) -> Type {
        return .init("timestamp(\(p)) \(withTimeZone ? "without time zone" : "with time zone")")
    }
    
    /// calendar date (year, month, day)
    public static let date: Type = .init("date")
    public static let dateArray: Type = .init("date[]")
    
    /// time of day (no time zone)
    public static let time: Type = .init("time")
    public static let timeArray: Type = .init("time[]")
    
    /// time of day (no time zone)
    public static let timeWithoutTimeZone: Type = .init("time without time zone")
    public static let timeWithoutTimeZoneArray: Type = .init("time without time zone[]")
    
    /// time of day, including time zone
    public static let timeWithTimeZone: Type = .init("time with time zone")
    public static let timeWithTimeZoneArray: Type = .init("time with time zone[]")
    
    /// time of day, including time zone
    public static let timetz: Type = .init("timetz")
    public static let timetzArray: Type = .init("timetz[]")

    /// time of day with nanoseconds precision
    public static let timeNs: Type = .init("time_ns")
    
    /// time of day
    public static func time(_ p: Int, withTimeZone: Bool = false) -> Type {
        return .init("time(\(p)) \(withTimeZone ? "without time zone" : "with time zone")")
    }
    
    /// time span
    public static let interval: Type = .init("interval")
    public static let intervalArray: Type = .init("interval[]")
    
    /// time span
    public static func interval(_ fields: String, p: Int) -> Type {
        return .init("interval \(fields) (\(p))")
    }
    
    // MARK: Boolean Type
    
    /// logical Boolean (true/false)
    public static let boolean: Type = .init("boolean")
    public static let booleanArray: Type = .init("boolean[]")
    
    /// logical Boolean (true/false)
    public static let bool: Type = .init("bool")
    public static let boolArray: Type = .init("bool[]")
    
    // MARK: Geometric Types
    
    /// geometric point on a plane
    public static let point: Type = .init("point")
    public static let pointArray: Type = .init("point[]")
    
    /// infinite line on a plane
    public static let line: Type = .init("line")
    public static let lineArray: Type = .init("line[]")
    
    /// line segment on a plane
    public static let lseg: Type = .init("lseg")
    public static let lsegArray: Type = .init("lseg[]")
    
    /// rectangular box on a plane
    public static let box: Type = .init("box")
    public static let boxArray: Type = .init("box[]")
    
    /// geometric path on a plane
    public static let path: Type = .init("path")
    public static let pathArray: Type = .init("path[]")
    
    /// closed geometric path on a plane
    public static let polygon: Type = .init("polygon")
    public static let polygonArray: Type = .init("polygon[]")
    
    /// circle on a plane
    public static let circle: Type = .init("circle")
    public static let circleArray: Type = .init("circle[]")
    
    // MARK: Network Address Types
    
    /// IPv4 or IPv6 network address
    public static let cidr: Type = .init("cidr")
    public static let cidrArray: Type = .init("cidr[]")
    
    /// IPv4 or IPv6 host address
    public static let inet: Type = .init("inet")
    public static let inetArray: Type = .init("inet[]")
    
    /// MAC (Media Access Control) address
    public static let macaddr: Type = .init("macaddr")
    public static let macaddrArray: Type = .init("macaddr[]")
    
    /// MAC (Media Access Control) address (EUI-64 format)
    public static let macaddr8: Type = .init("macaddr8")
    public static let macaddr8Array: Type = .init("macaddr8[]")
    
    // MARK: Bit String Types
    
    /// fixed-length bit string
    public static let bit: Type = .init("bit")
    public static let bitArray: Type = .init("bit[]")
    /// fixed-length bit string
    public static func bit(_ v: Int) -> Type { .init("bit(\(v))") }
    
    /// variable-length bit string
    public static let bitVarying: Type = .init("bit varying")
    public static let bitVaryingArray: Type = .init("bit varying[]")
    /// variable-length bit string
    public static func bitVarying(_ v: Int) -> Type { .init("bit varying(\(v))") }
    
    /// variable-length bit string
    public static let varbit: Type = .init("varbit")
    /// variable-length bit string
    public static func varbit(_ v: Int) -> Type { .init("varbit(\(v))") }
    
    // MARK: Text Search Types
    
    /// text search document
    public static let tsvector: Type = .init("tsvector")
    public static let tsvectorArray: Type = .init("tsvector[]")
    
    /// text search query
    public static let tsquery: Type = .init("tsquery")
    public static let tsqueryArray: Type = .init("tsquery[]")
    
    // MARK: UUID Type
    
    /// universally unique identifier
    public static let uuid: Type = .init("uuid")
    public static let uuidArray: Type = .init("uuid[]")
    
    // MARK: XML Type
    
    /// XML data
    public static let xml: Type = .init("xml")
    public static let xmlArray: Type = .init("xml[]")
    
    // MARK: Postgres JSON Types
    
    /// textual JSON data
    public static let json: Type = .init("json")
    public static let jsonArray: Type = .init("json[]")
    
    /// binary JSON data, decomposed
    public static let jsonb: Type = .init("jsonb")
    public static let jsonbArray: Type = .init("jsonb[]")

    /// dynamically typed value
    public static let variant: Type = .init("variant")
    
    // MARK: Postgres Built-in Range Types
    
    /// Range of integer
    public static let int4range: Type = .init("int4range")
    public static let int4rangeArray: Type = .init("int4range[]")

    /// Range of bigint
    public static let int8range: Type = .init("int8range")
    public static let int8rangeArray: Type = .init("int8range[]")

    /// Range of numeric
    public static let numrange: Type = .init("numrange")
    public static let numrangeArray: Type = .init("numrange[]")

    /// Range of timestamp without time zone
    public static let tsrange: Type = .init("tsrange")
    public static let tsrangeArray: Type = .init("tsrange[]")

    /// Range of timestamp with time zone
    public static let tstzrange: Type = .init("tstzrange")
    public static let tstzrangeArray: Type = .init("tstzrange[]")

    /// Range of date
    public static let daterange: Type = .init("daterange")
    public static let daterangeArray: Type = .init("daterange[]")
    
    // MARK: Object Identifier Types
    
    /// numeric object identifier
    public static let oid: Type = .init("oid")
    public static let oidArray: Type = .init("oid[]")
    
    /// function name
    public static let regproc: Type = .init("regproc")
    public static let regprocArray: Type = .init("regproc[]")
    
    /// function name
    public static let pg_proc: Type = .init("pg_proc")
    public static let pg_procArray: Type = .init("pg_proc[]")
    
    /// function with argument types
    public static let regprocedure: Type = .init("regprocedure")
    public static let regprocedureArray: Type = .init("regprocedure[]")
    
    /// operator name
    public static let regoper: Type = .init("regoper")
    public static let regoperArray: Type = .init("regoper[]")
    
    /// operator name
    public static let pg_operator: Type = .init("pg_operator")
    public static let pg_operatorArray: Type = .init("pg_operator[]")
    
    /// operator with argument types
    public static let regoperator: Type = .init("regoperator")
    public static let regoperatorArray: Type = .init("regoperator[]")
    
    /// relation name
    public static let regclass: Type = .init("regclass")
    public static let regclassArray: Type = .init("regclass[]")
    
    /// relation name
    public static let pg_class: Type = .init("pg_class")
    public static let pg_classArray: Type = .init("pg_class[]")
    
    /// data type name
    public static let regtype: Type = .init("regtype")
    public static let regtypeArray: Type = .init("regtype[]")
    
    /// data type name
    public static let pg_type: Type = .init("pg_type")
    public static let pg_typeArray: Type = .init("pg_type[]")
    
    /// role name
    public static let regrole: Type = .init("regrole")
    public static let regroleArray: Type = .init("regrole[]")
    
    /// role name
    public static let pg_authid: Type = .init("pg_authid")
    public static let pg_authidArray: Type = .init("pg_authid[]")
    
    /// namespace name
    public static let regnamespace: Type = .init("regnamespace")
    public static let regnamespaceArray: Type = .init("regnamespace[]")
    
    /// namespace name
    public static let pg_namespace: Type = .init("pg_namespace")
    public static let pg_namespaceArray: Type = .init("pg_namespace[]")
    
    /// text search configuration
    public static let regconfig: Type = .init("regconfig")
    public static let regconfigArray: Type = .init("regconfig[]")
    
    /// text search configuration
    public static let pg_ts_config: Type = .init("pg_ts_config")
    public static let pg_ts_configArray: Type = .init("pg_ts_config[]")
    
    /// text search dictionary
    public static let regdictionary: Type = .init("regdictionary")
    public static let regdictionaryArray: Type = .init("regdictionary[]")
    
    /// text search dictionary
    public static let pg_ts_dict: Type = .init("pg_ts_dict")
    public static let pg_ts_dictArray: Type = .init("pg_ts_dict[]")
    
    // MARK: Postgres Log Sequence Number
    
    /// PostgreSQL Log Sequence Number
    public static let pgLsn: Type = .init("pg_lsn")
    public static let pgLsnArray: Type = .init("pg_lsn[]")
    
    // MARK: Postgres Pseudo-Types
    // The PostgreSQL type system contains a number of special-purpose entries that are collectively called pseudo-types.
    // A pseudo-type cannot be used as a column data type, but it can be used to declare a function's argument or result type.
    // Each of the available pseudo-types is useful in situations where a function's behavior does not correspond to
    // simply taking or returning a value of a specific SQL data type.
    
    /// Indicates that a function accepts any input data type.
    public static let any: Type = .init("any")
    
    /// Indicates that a function accepts any data type (see Section 37.2.5).
    public static let anyelement: Type = .init("anyelement")
    
    /// Indicates that a function accepts any array data type (see Section 37.2.5).
    public static let anyarray: Type = .init("anyarray")
    
    /// Indicates that a function accepts any non-array data type (see Section 37.2.5).
    public static let anynonarray: Type = .init("anynonarray")
    
    /// Indicates that a function accepts any enum data type (see Section 37.2.5 and Section 8.7).
    public static let anyenum: Type = .init("anyenum")
    
    /// Indicates that a function accepts any range data type (see Section 37.2.5 and Section 8.17).
    public static let anyrange: Type = .init("anyrange")
    
    /// Indicates that a function accepts or returns a null-terminated C string.
    public static let cstring: Type = .init("cstring")
    
    /// Indicates that a function accepts or returns a server-internal data type.
    public static let `internal`: Type = .init("internal")
    
    /// A procedural language call handler is declared to return language_handler.
    public static let language_handler: Type = .init("language_handler")
    
    /// A foreign-data wrapper handler is declared to return fdw_handler.
    public static let fdw_handler: Type = .init("fdw_handler")
    
    /// An index access method handler is declared to return index_am_handler.
    public static let index_am_handler: Type = .init("index_am_handler")
    
    /// A tablesample method handler is declared to return tsm_handler.
    public static let tsm_handler: Type = .init("tsm_handler")
    
    /// Identifies a function taking or returning an unspecified row type.
    public static let record: Type = .init("record")
    
    /// A trigger function is declared to return trigger.
    public static let trigger: Type = .init("trigger")
    
    /// An event trigger function is declared to return event_trigger.
    public static let event_trigger: Type = .init("event_trigger")
    
    /// Identifies a representation of DDL commands that is available to event triggers.
    public static let pg_ddl_command: Type = .init("pg_ddl_command")
    
    /// Indicates that a function returns no value.
    public static let void: Type = .init("void")
    
    /// Identifies a not-yet-resolved type, e.g. of an undecorated string literal.
    public static let unknown: Type = .init("unknown")
    
    /// An obsolete type name that formerly served many of the above purposes.
    public static let opaque: Type = .init("opaque")
    
    // MARK: Other
    
    /// user-level transaction ID snapshot
    public static let txid_snapshot: Type = .init("txid_snapshot")
    public static let txid_snapshotArray: Type = .init("txid_snapshot[]")
    
    // MARK: -
    // MARK: Array Subscript
    
    public subscript () -> Type { .init("\(name)[]") }
    
    // MARK: -
    // MARK: Custom
    
    public static func custom(_ name: String) -> Type { .init(name) }
    public static func customArray(_ name: String) -> Type { .init(name + "[]") }
}
