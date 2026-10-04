// Compatibility aliases for the SwifQL -> SQL identity migration.
//
// Canonical implementation source must use SQL-prefixed names.
// These declarations exist only to keep existing downstream source compiling
// while producing deprecation diagnostics that point to the canonical API.

@available(*, deprecated, renamed: "AnySQLEnum")
public typealias AnySwifQLEnum = AnySQLEnum

@available(*, deprecated, renamed: "SQLBool")
public typealias SwifQLBool = SQLBool

@available(*, deprecated, renamed: "SQLClauseKind")
public typealias SwifQLClauseKind = SQLClauseKind

@available(*, deprecated, renamed: "SQLClauseOwner")
public typealias SwifQLClauseOwner = SQLClauseOwner

@available(*, deprecated, renamed: "SQLCodable")
public typealias SwifQLCodable = SQLCodable

@available(*, deprecated, renamed: "SQLEncodable")
public typealias SwifQLEncodable = SQLEncodable

@available(*, deprecated, renamed: "SQLEnum")
public typealias SwifQLEnum = SQLEnum

@available(*, deprecated, renamed: "SQLGroupByPart")
public typealias SwifQLGroupByPart = SQLGroupByPart

@available(*, deprecated, renamed: "SQLHybridOperator")
public typealias SwifQLHybridOperator = SQLHybridOperator

@available(*, deprecated, renamed: "SQLHybridRepresentationKey")
public typealias SwifQLHybridRepresentationKey = SQLHybridRepresentationKey

@available(*, deprecated, renamed: "SQLJoinBuilder")
public typealias SwifQLJoinBuilder = SQLJoinBuilder

@available(*, deprecated, renamed: "SQLKeyPathable")
public typealias SwifQLKeyPathable = SQLKeyPathable

@available(*, deprecated, renamed: "SQLObservedParts")
public typealias SwifQLObservedParts = SQLObservedParts

@available(*, deprecated, renamed: "SQLObservedPrepared")
public typealias SwifQLObservedPrepared = SQLObservedPrepared

@available(*, deprecated, renamed: "SQLOrderByPart")
public typealias SwifQLOrderByPart = SQLOrderByPart

@available(*, deprecated, renamed: "SQLPart")
public typealias SwifQLPart = SQLPart

@available(*, deprecated, renamed: "SQLPartAlias")
public typealias SwifQLPartAlias = SQLPartAlias

@available(*, deprecated, renamed: "SQLPartArray")
public typealias SwifQLPartArray = SQLPartArray

@available(*, deprecated, renamed: "SQLPartBool")
public typealias SwifQLPartBool = SQLPartBool

@available(*, deprecated, renamed: "SQLPartCatalog")
public typealias SwifQLPartCatalog = SQLPartCatalog

@available(*, deprecated, renamed: "SQLPartColumn")
public typealias SwifQLPartColumn = SQLPartColumn

@available(*, deprecated, renamed: "SQLPartDate")
public typealias SwifQLPartDate = SQLPartDate

@available(*, deprecated, renamed: "SQLPartIdentifier")
public typealias SwifQLPartIdentifier = SQLPartIdentifier

@available(*, deprecated, renamed: "SQLPartKeyPath")
public typealias SwifQLPartKeyPath = SQLPartKeyPath

@available(*, deprecated, renamed: "SQLPartLambda")
public typealias SwifQLPartLambda = SQLPartLambda

@available(*, deprecated, renamed: "SQLPartNull")
public typealias SwifQLPartNull = SQLPartNull

@available(*, deprecated, renamed: "SQLPartOperator")
public typealias SwifQLPartOperator = SQLPartOperator

@available(*, deprecated, renamed: "SQLPartSafeValue")
public typealias SwifQLPartSafeValue = SQLPartSafeValue

@available(*, deprecated, renamed: "SQLPartSampling")
public typealias SwifQLPartSampling = SQLPartSampling

@available(*, deprecated, renamed: "SQLPartSchema")
public typealias SwifQLPartSchema = SQLPartSchema

@available(*, deprecated, renamed: "SQLPartTable")
public typealias SwifQLPartTable = SQLPartTable

@available(*, deprecated, renamed: "SQLPartTableWithAlias")
public typealias SwifQLPartTableWithAlias = SQLPartTableWithAlias

@available(*, deprecated, renamed: "SQLPartType")
public typealias SwifQLPartType = SQLPartType

@available(*, deprecated, renamed: "SQLPartUnsafeValue")
public typealias SwifQLPartUnsafeValue = SQLPartUnsafeValue

@available(*, deprecated, renamed: "SQLPredicate")
public typealias SwifQLPredicate = SQLPredicate

@available(*, deprecated, renamed: "SQLPrepared")
public typealias SwifQLPrepared = SQLPrepared

@available(*, deprecated, renamed: "SQLRawRepresentable")
public typealias SwifQLRawRepresentable = SQLRawRepresentable

@available(*, deprecated, renamed: "SQLRenderContext")
public typealias SwifQLRenderContext = SQLRenderContext

@available(*, deprecated, renamed: "SQLRenderScope")
public typealias SwifQLRenderScope = SQLRenderScope

@available(*, deprecated, renamed: "SQLSelectBuilder")
public typealias SwifQLSelectBuilder = SQLSelectBuilder

@available(*, deprecated, renamed: "SQLSemanticRole")
public typealias SwifQLSemanticRole = SQLSemanticRole

@available(*, deprecated, renamed: "SQLSemanticRoleCarryingPart")
public typealias SwifQLSemanticRoleCarryingPart = SQLSemanticRoleCarryingPart

@available(*, deprecated, renamed: "SQLSplittedQuery")
public typealias SwifQLSplittedQuery = SQLSplittedQuery

@available(*, deprecated, renamed: "SQLStarExcludePart")
public typealias SwifQLStarExcludePart = SQLStarExcludePart

@available(*, deprecated, renamed: "SQLStarRenamePart")
public typealias SwifQLStarRenamePart = SQLStarRenamePart

@available(*, deprecated, renamed: "SQLStarReplacePart")
public typealias SwifQLStarReplacePart = SQLStarReplacePart

@available(*, deprecated, renamed: "SQLStructuralFramePart")
public typealias SwifQLStructuralFramePart = SQLStructuralFramePart

@available(*, deprecated, renamed: "SQLStructuralRegion")
public typealias SwifQLStructuralRegion = SQLStructuralRegion

@available(*, deprecated, renamed: "SQLUniversalKeyPath")
public typealias SwifQLUniversalKeyPath = SQLUniversalKeyPath

@available(*, deprecated, renamed: "SQLUniversalKeyPathSimple")
public typealias SwifQLUniversalKeyPathSimple = SQLUniversalKeyPathSimple

@available(*, deprecated, renamed: "SQLUnsafeValueObservation")
public typealias SwifQLUnsafeValueObservation = SQLUnsafeValueObservation

@available(*, deprecated, renamed: "SQLUnsafeValueOccurrence")
public typealias SwifQLUnsafeValueOccurrence = SQLUnsafeValueOccurrence

@available(*, deprecated, renamed: "SQLUnsafeValueTrace")
public typealias SwifQLUnsafeValueTrace = SQLUnsafeValueTrace

@available(*, deprecated, renamed: "SQLable")
public typealias SwifQLable = SQLable

@available(*, deprecated, renamed: "SQLableArraySeparator")
public typealias SwifQLableArraySeparator = SQLableArraySeparator

@available(*, deprecated, renamed: "SQLableParts")
public typealias SwifQLableParts = SQLableParts

@available(*, deprecated, renamed: "SQLNull")
public var SwifQLNull: SQLPartNull { SQLNull }
