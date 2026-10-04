//
//  Operator.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

public typealias Op = Operator
public typealias Operator = SQLPartOperator

extension SQLPartOperator {
    public typealias Result = SQLPartOperator
    
    public static var left: Result { "LEFT".operator }
    public static var right: Result { "RIGHT".operator }
    public static var inner: Result { "INNER".operator }
    public static var outer: Result { "OUTER".operator }
    public static var cross: Result { "CROSS".operator }
    public static var lateral: Result { "LATERAL".operator }
    public static var action: Result { "ACTION".operator }
    public static var no: Result { "NO".operator }
    public static var references: Result { "REFERENCES".operator }
    public static var check: Result { "CHECK".operator }
    public static var add: Result { "ADD".operator }
    public static var primary: Result { "PRIMARY".operator }
    public static var key: Result { "KEY".operator }
    public static var unique: Result { "UNIQUE".operator }
    public static var select: Result { "SELECT".operator }
    public static var distinct: Result { "DISTINCT".operator }
    public static var `as`: Result { "as".operator }
    public static var any: Result { "ANY".operator }
    public static var delete: Result { "DELETE".operator }
    public static var from: Result { "FROM".operator }
    public static var join: Result { "JOIN".operator }
    public static var `where`: Result { "WHERE".operator }
    public static var having: Result { "HAVING".operator }
    public static var group: Result { "GROUP".operator }
    public static var order: Result { "ORDER".operator }
    public static var by: Result { "BY".operator }
    public static var insert: Result { "INSERT".operator }
    public static var into: Result { "INTO".operator }
    public static var values: Result { "VALUES".operator }
    public static var union: Result { "UNION".operator }
    public static var all: Result { "ALL".operator }
    public static var returning: Result { "RETURNING".operator }
    public static var exists: Result { "EXISTS".operator }
    public static var and: Result { "AND".operator }
    public static var or: Result { "OR".operator }
    public static var greaterThan: Result { ">".operator }
    public static var lessThan: Result { "<".operator }
    public static var greaterThanOrEqual: Result { ">=".operator }
    public static var lessThanOrEqual: Result { "<=".operator }
    public static var equal: Result { "=".operator }
    public static var notEqual: Result { "!=".operator }
    public static var `if`: Result { "IF".operator }
    public static var `in`: Result { "IN".operator }
    public static var notIn: Result { "NOT IN".operator }
    public static var like: Result { "LIKE".operator }
    public static var notLike: Result { "NOT LIKE".operator }
    public static var ilike: Result { "ILIKE".operator }
    public static var notILike: Result { "NOT ILIKE".operator }
    public static var fulltext: Result { "@@".operator }
    public static var isNull: Result { "IS NULL".operator }
    public static var isNotNull: Result { "IS NOT NULL".operator }
    public static var contains: Result { "@>".operator }
    public static var containedBy: Result { "<@".operator }
    public static var on: Result { "ON".operator }
    public static var `case`: Result { "CASE".operator }
    public static var when: Result { "WHEN".operator }
    public static var then: Result { "THEN".operator }
    public static var `else`: Result { "ELSE".operator }
    public static var end: Result { "END".operator }
    public static var null: Result { "NULL".operator }
    public static var `do`: Result { "DO".operator }
    public static var conflict: Result { "CONFLICT".operator }
    public static var constraint: Result { "CONSTRAINT".operator }
    public static var nothing: Result { "NOTHING".operator }
    public static var asc: Result { "ASC".operator }
    public static var desc: Result { "DESC".operator }
    public static var limit: Result { "LIMIT".operator }
    public static var offset: Result { "OFFSET".operator }
    public static var `for`: Result { "FOR".operator }
    public static var filter: Result { "FILTER".operator }
    public static var array: Result { "ARRAY".operator }
    public static var doubleDollar: Result { "$$".operator }
    public static var between: Result { "BETWEEN".operator }
    public static var notBetween: Result { "NOT BETWEEN".operator }
    public static var not: Result { "NOT".operator }
    public static var timestamp: Result { "TIMESTAMP".operator }
    public static var with: Result { "WITH".operator }
    public static var timeZone: Result { "TIME ZONE".operator }
    public static var epoch: Result { "EPOCH".operator }
    public static var interval: Result { "INTERVAL".operator }
    public static var date: Result { "DATE".operator }
    public static var millenium: Result { "MILLENNIUM".operator }
    public static var microseconds: Result { "MICROSECONDS".operator }
    public static var milliseconds: Result { "MILLISECONDS".operator }
    public static var isoYear: Result { "ISOYEAR".operator }
    public static var isoDoW: Result { "ISODOW".operator }
    public static var hour: Result { "HOUR".operator }
    public static var time: Result { "TIME".operator }
    public static var minute: Result { "MINUTE".operator }
    public static var month: Result { "MONTH".operator }
    public static var quarter: Result { "QUARTER".operator }
    public static var second: Result { "SECOND".operator }
    public static var week: Result { "WEEK".operator }
    public static var year: Result { "YEAR".operator }
    public static var decade: Result { "DECADE".operator }
    public static var century: Result { "CENTURY".operator }
    public static var overlaps: Result { "OVERLAPS".operator }
    public static var over: Result { "OVER".operator }
    public static var doublePrecision: Result { "DOUBLE PRECISION".operator }
    public static var nulls: Result { "NULLS".operator }
    public static var first: Result { "FIRST".operator }
    public static var last: Result { "LAST".operator }
    public static var create: Result { "CREATE".operator }
    public static var index: Result { "INDEX".operator }
    public static var type: Result { "TYPE".operator }
    public static var function: Result { "FUNCTION".operator }
    public static var table: Result { "TABLE".operator }
    public static var `enum`: Result { "ENUM".operator }
    public static var range: Result { "RANGE".operator }
    public static var subtype: Result { "SUBTYPE".operator }
    public static var subtypeOpClass: Result { "SUBTYPE_OPCLASS".operator }
    public static var collate: Result { "COLLATE".operator }
    public static var collation: Result { "COLLATION".operator }
    public static var collatable: Result { "COLLATABLE".operator }
    public static var canonical: Result { "CANONICAL".operator }
    public static var subtypeDiff: Result { "SUBTYPE_DIFF".operator }
    public static var input: Result { "INPUT".operator }
    public static var output: Result { "OUTPUT".operator }
    public static var receive: Result { "RECEIVE".operator }
    public static var send: Result { "SEND".operator }
    public static var typmodIn: Result { "TYPMOD_IN".operator }
    public static var typmodOut: Result { "TYPMOD_OUT".operator }
    public static var analyze: Result { "ANALYZE".operator }
    public static var internalLength: Result { "INTERNALLENGTH".operator }
    public static var variable: Result { "VARIABLE".operator }
    public static var passedByValue: Result { "PASSEDBYVALUE".operator }
    public static var alignment: Result { "ALIGNMENT".operator }
    public static var storage: Result { "STORAGE".operator }
    public static var category: Result { "CATEGORY".operator }
    public static var preferred: Result { "PREFERRED".operator }
    public static var `default`: Result { "DEFAULT".operator }
    public static var element: Result { "ELEMENT".operator }
    public static var delimiter: Result { "DELIMITER".operator }
    public static var returns: Result { "RETURNS".operator }
    public static var setOf: Result { "SETOF".operator }
    public static var begin: Result { "BEGIN".operator }
    public static var commit: Result { "COMMIT".operator }
    public static var rollback: Result { "ROLLBACK".operator }
    public static var `return`: Result { "RETURN".operator }
    public static var raise: Result { "RAISE".operator }
    public static var exception: Result { "EXCEPTION".operator }
    public static var replace: Result { "REPLACE".operator }
    public static var semicolon: Result { ";".operator }
    public static var openBracket: Result { "(".operator }
    public static var closeBracket: Result { ")".operator }
    public static var openSquareBracket: Result { "[".operator }
    public static var closeSquareBracket: Result { "]".operator }
    public static var openBrace: Result { "{".operator }
    public static var closeBrace: Result { "}".operator }
    public static var comma: Result { ",".operator }
    public static var period: Result { ".".operator }
    public static var space: Result { `_` }
    public static var `_`: Result { " ".operator }
    public static var using: Result { "USING".operator }
    public static var owner: Result { "OWNER".operator }
    public static var to: Result { "TO".operator }
    public static var currentUser: Result { "CURRENT_USER".operator }
    public static var sessionUser: Result { "SESSION_USER".operator }
    public static var rename: Result { "RENAME".operator }
    public static var column: Result { "COLUMN".operator }
    public static var attribute: Result { "ATTRIBUTE".operator }
    public static var cascade: Result { "CASCADE".operator }
    public static var restrict: Result { "RESTRICT".operator }
    public static var schema: Result { "SCHEMA".operator }
    public static var foreign: Result { "FOREIGN".operator }
    public static var value: Result { "VALUE".operator }
    public static var before: Result { "BEFORE".operator }
    public static var after: Result { "AFTER".operator }
    public static var drop: Result { "DROP".operator }
    public static var update: Result { "UPDATE".operator }
    public static var alter: Result { "ALTER".operator }
    public static var set: Result { "SET".operator }
    public static var data: Result { "DATA".operator }
    public static var partition: Result { "PARTITION".operator }
    public static var window: Result { "WINDOW".operator }
    public static func custom(_ v: String) -> Result { v.operator }
    
    public var left: Result { concatWith(.left) }
    public var right: Result { concatWith(.right) }
    public var inner: Result { concatWith(.inner) }
    public var outer: Result { concatWith(.outer) }
    public var cross: Result { concatWith(.cross) }
    public var lateral: Result { concatWith(.lateral) }
    public var no: Result { concatWith(.no) }
    public var action: Result { concatWith(.action) }
    public var references: Result { concatWith(.references) }
    public var add: Result { concatWith(.add) }
    public var check: Result { concatWith(.check) }
    public var primary: Result { concatWith(.primary) }
    public var key: Result { concatWith(.key) }
    public var unique: Result { concatWith(.unique) }
    public var select: Result { concatWith(.select) }
    public var distinct: Result { concatWith(.distinct) }
    public var `as`: Result { concatWith(.as) }
    public var any: Result { concatWith(.any) }
    public var delete: Result { concatWith(.delete) }
    public var from: Result { concatWith(.from) }
    public var join: Result { concatWith(.join) }
    public var `where`: Result { concatWith(.where) }
    public var having: Result { concatWith(.having) }
    public var group: Result { concatWith(.group) }
    public var order: Result { concatWith(.order) }
    public var by: Result { concatWith(.by) }
    public var insert: Result { concatWith(.insert) }
    public var into: Result { concatWith(.into) }
    public var values: Result { concatWith(.values) }
    public var union: Result { concatWith(.union) }
    public var returning: Result { concatWith(.returning) }
    public var exists: Result { concatWith(.exists) }
    public var and: Result { concatWith(.and) }
    public var or: Result { concatWith(.or) }
    public var greaterThan: Result { concatWith(.greaterThan) }
    public var lessThan: Result { concatWith(.lessThan) }
    public var greaterThanOrEqual: Result { concatWith(.greaterThanOrEqual) }
    public var lessThanOrEqual: Result { concatWith(.lessThanOrEqual) }
    public var equal: Result { concatWith(.equal) }
    public var notEqual: Result { concatWith(.notEqual) }
    public var `if`: Result { concatWith(.if) }
    public var `in`: Result { concatWith(.in) }
    public var notIn: Result { concatWith(.notIn) }
    public var like: Result { concatWith(.like) }
    public var notLike: Result { concatWith(.notLike) }
    public var ilike: Result { concatWith(.ilike) }
    public var notILike: Result { concatWith(.notILike) }
    public var fulltext: Result { concatWith(.fulltext) }
    public var isNull: Result { concatWith(.isNull) }
    public var isNotNull: Result { concatWith(.isNotNull) }
    public var contains: Result { concatWith(.contains) }
    public var containedBy: Result { concatWith(.containedBy) }
    public var on: Result { concatWith(.on) }
    public var `case`: Result { concatWith(.case) }
    public var when: Result { concatWith(.when) }
    public var then: Result { concatWith(.then) }
    public var `else`: Result { concatWith(.else) }
    public var end: Result { concatWith(.end) }
    public var null: Result { concatWith(.null) }
    public var `do`: Result { concatWith(.do) }
    public var conflict: Result { concatWith(.conflict) }
    public var constraint: Result { concatWith(.constraint) }
    public var nothing: Result { concatWith(.nothing) }
    public var asc: Result { concatWith(.asc) }
    public var desc: Result { concatWith(.desc) }
    public var limit: Result { concatWith(.limit) }
    public var offset: Result { concatWith(.offset) }
    public var `for`: Result { concatWith(.for) }
    public var filter: Result { concatWith(.filter) }
    public var array: Result { concatWith(.array) }
    public var doubleDollar: Result { concatWith(.doubleDollar) }
    public var between: Result { concatWith(.between) }
    public var notBetween: Result { concatWith(.notBetween) }
    public var not: Result { concatWith(.not) }
    public var timestamp: Result { concatWith(.timestamp) }
    public var with: Result { concatWith(.with) }
    public var timeZone: Result { concatWith(.timeZone) }
    public var epoch: Result { concatWith(.epoch) }
    public var interval: Result { concatWith(.interval) }
    public var date: Result { concatWith(.date) }
    public var millenium: Result { concatWith(.millenium) }
    public var microseconds: Result { concatWith(.microseconds) }
    public var milliseconds: Result { concatWith(.milliseconds) }
    public var isoYear: Result { concatWith(.isoYear) }
    public var isoDoW: Result { concatWith(.isoDoW) }
    public var hour: Result { concatWith(.hour) }
    public var time: Result { concatWith(.time) }
    public var minute: Result { concatWith(.minute) }
    public var month: Result { concatWith(.month) }
    public var quarter: Result { concatWith(.quarter) }
    public var second: Result { concatWith(.second) }
    public var week: Result { concatWith(.week) }
    public var year: Result { concatWith(.year) }
    public var decade: Result { concatWith(.decade) }
    public var century: Result { concatWith(.century) }
    public var overlaps: Result { concatWith(.overlaps) }
    public var over: Result { concatWith(.over) }
    public var doublePrecision: Result { concatWith(.doublePrecision) }
    public var nulls: Result { concatWith(.nulls) }
    public var first: Result { concatWith(.first) }
    public var last: Result { concatWith(.last) }
    public var create: Result { concatWith(.create) }
    public var index: Result { concatWith(.index) }
    public var type: Result { concatWith(.type) }
    public var function: Result { concatWith(.function) }
    public var table: Result { concatWith(.table) }
    public var `enum`: Result { concatWith(.enum) }
    public var range: Result { concatWith(.range) }
    public var subtype: Result { concatWith(.subtype) }
    public var subtypeOpClass: Result { concatWith(.subtypeOpClass) }
    public var collate: Result { concatWith(.collate) }
    public var collation: Result { concatWith(.collation) }
    public var collatable: Result { concatWith(.collatable) }
    public var canonical: Result { concatWith(.canonical) }
    public var subtypeDiff: Result { concatWith(.subtypeDiff) }
    public var input: Result { concatWith(.input) }
    public var output: Result { concatWith(.output) }
    public var receive: Result { concatWith(.receive) }
    public var send: Result { concatWith(.send) }
    public var typmodIn: Result { concatWith(.typmodIn) }
    public var typmodOut: Result { concatWith(.typmodOut) }
    public var analyze: Result { concatWith(.analyze) }
    public var internalLength: Result { concatWith(.internalLength) }
    public var variable: Result { concatWith(.variable) }
    public var passedByValue: Result { concatWith(.passedByValue) }
    public var alignment: Result { concatWith(.alignment) }
    public var storage: Result { concatWith(.storage) }
    public var category: Result { concatWith(.category) }
    public var preferred: Result { concatWith(.preferred) }
    public var `default`: Result { concatWith(.default) }
    public var element: Result { concatWith(.element) }
    public var delimiter: Result { concatWith(.delimiter) }
    public var returns: Result { concatWith(.returns) }
    public var setOf: Result { concatWith(.setOf) }
    public var begin: Result { concatWith(.begin) }
    public var commit: Result { concatWith(.commit) }
    public var rollback: Result { concatWith(.rollback) }
    public var `return`: Result { concatWith(.return) }
    public var raise: Result { concatWith(.raise) }
    public var exception: Result { concatWith(.exception) }
    public var replace: Result { concatWith(.replace) }
    public var semicolon: Result { concatWith(.semicolon) }
    public var openBracket: Result { concatWith(.openBracket) }
    public var closeBracket: Result { concatWith(.closeBracket) }
    public var openSquareBracket: Result { concatWith(.openSquareBracket) }
    public var closeSquareBracket: Result { concatWith(.closeSquareBracket) }
    public var openBrace: Result { concatWith(.openBrace) }
    public var closeBrace: Result { concatWith(.closeBrace) }
    public var comma: Result { concatWith(.comma) }
    public var period: Result { concatWith(.period) }
    public var space: Result { concatWith(.space) }
    public var `_`: Result { concatWith(.`_`) }
    public var using: Result { concatWith(.using) }
    public var owner: Result { concatWith(.owner) }
    public var to: Result { concatWith(.to) }
    public var currentUser: Result { concatWith(.currentUser) }
    public var sessionUser: Result { concatWith(.sessionUser) }
    public var rename: Result { concatWith(.rename) }
    public var column: Result { concatWith(.column) }
    public var attribute: Result { concatWith(.attribute) }
    public var cascade: Result { concatWith(.cascade) }
    public var restrict: Result { concatWith(.restrict) }
    public var schema: Result { concatWith(.schema) }
    public var foreign: Result { concatWith(.foreign) }
    public var value: Result { concatWith(.value) }
    public var before: Result { concatWith(.before) }
    public var after: Result { concatWith(.after) }
    public var drop: Result { concatWith(.drop) }
    public var update: Result { concatWith(.update) }
    public var alter: Result { concatWith(.alter) }
    public var set: Result { concatWith(.set) }
    public var data: Result { concatWith(.data) }
    public var partition: Result { concatWith(.partition) }
    public var window: Result { concatWith(.window) }
    public func custom(_ v: String) -> Result { concatWith(.custom(v)) }
    
    private func concatWith(_ operator: Result) -> Result {
        (_value + `operator`._value).operator
    }
}

extension String {
    fileprivate var `operator`: SQLPartOperator { .init(self) }
}
