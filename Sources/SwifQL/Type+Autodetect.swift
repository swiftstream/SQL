//
//  Type+Autodetect.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

extension Type {
    public static func auto<T>(from type: T.Type, isPrimary: Bool = false) -> Type {
        switch type {
        case is Optional<String>.Type: fallthrough
        case is String.Type: return .text
        
        case is Optional<[String]>.Type: fallthrough
        case is [String].Type: return .textArray
        
        case is Optional<UUID>.Type: fallthrough
        case is UUID.Type: return .uuid
        
        case is Optional<[UUID]>.Type: fallthrough
        case is [UUID].Type: return .uuidArray
        
        case is Optional<Double>.Type: fallthrough
        case is Double.Type: return .decimal
        
        case is Optional<[Double]>.Type: fallthrough
        case is [Double].Type: return .decimalArray
        
        case is Optional<Float>.Type: fallthrough
        case is Float.Type: return .float4
        
        case is Optional<[Float]>.Type: fallthrough
        case is [Float].Type: return .float4Array
        
        case is Optional<UInt>.Type: fallthrough
        case is UInt.Type: fallthrough
        
        case is Optional<UInt8>.Type: fallthrough
        case is UInt8.Type: fallthrough
        
        case is Optional<UInt16>.Type: fallthrough
        case is UInt16.Type: fallthrough
        
        case is Optional<UInt32>.Type: fallthrough
        case is UInt32.Type: fallthrough
        
        case is Optional<UInt64>.Type: fallthrough
        case is UInt64.Type: return .int
        
        case is Optional<[UInt]>.Type: fallthrough
        case is [UInt].Type: fallthrough
        
        case is Optional<[UInt8]>.Type: fallthrough
        case is [UInt8].Type: fallthrough
        
        case is Optional<[UInt16]>.Type: fallthrough
        case is [UInt16].Type: fallthrough
        
        case is Optional<[UInt32]>.Type: fallthrough
        case is [UInt32].Type: fallthrough
        
        case is Optional<[UInt64]>.Type: fallthrough
        case is [UInt64].Type: return .intArray
        
        case is Optional<Int8>.Type: fallthrough
        case is Int8.Type: fallthrough
        
        case is Optional<Int16>.Type: fallthrough
        case is Int16.Type: fallthrough
        
        case is Optional<Int32>.Type: fallthrough
        case is Int32.Type: fallthrough
        
        case is Optional<Int>.Type: fallthrough
        case is Int.Type:
            if isPrimary {
                return .serial
            } else {
                return .int
            }
        
        case is Optional<Int64>.Type: fallthrough
        case is Int64.Type:
            if isPrimary {
                return .bigserial
            } else {
                return .bigint
            }
        
        case is Optional<[Int8]>.Type: fallthrough
        case is [Int8].Type: fallthrough
        
        case is Optional<[Int16]>.Type: fallthrough
        case is [Int16].Type: fallthrough
        
        case is Optional<[Int32]>.Type: fallthrough
        case is [Int32].Type: fallthrough
        
        case is Optional<[Int]>.Type: fallthrough
        case is [Int].Type: return .intArray
        
        case is Optional<[Int64]>.Type: fallthrough
        case is [Int64].Type: return .bigintArray

        case is Optional<PureDate>.Type: fallthrough
        case is PureDate.Type: return .date

        case is Optional<PureTime>.Type: fallthrough
        case is PureTime.Type: return .time
        
        case is Optional<Date>.Type: fallthrough
        case is Date.Type: return .timestamptz
        
        case is Optional<[Date]>.Type: fallthrough
        case is [Date].Type: return .timestamptzArray
        
        case is Optional<Data>.Type: fallthrough
        case is Data.Type: return .bytea
        
        case is Optional<[Data]>.Type: fallthrough
        case is [Data].Type: return .byteaArray
        
        case is AnyOptionalEnum.Type:
            guard let t = type as? AnyOptionalEnum.Type else { fallthrough }
            if let st = type as? Schemable.Type {
                return .custom(st.schemaName + "." + t.name)
            } else {
                return .custom(t.name)
            }
            
        case is AnyOptionalEnumArray.Type:
            guard let t = type as? AnyOptionalEnumArray.Type else { fallthrough }
            if let st = type as? Schemable.Type {
                return .customArray(st.schemaName + "." + t.name)
            } else {
                return .customArray(t.name)
            }
            
        case is AnySQLEnum.Type:
            guard let t = type as? AnySQLEnum.Type else { fallthrough }
            if let st = type as? Schemable.Type {
                return .custom(st.schemaName + "." + t.name)
            } else {
                return .custom(t.name)
            }
            
        case is _AnySQLEnumArray.Type:
            guard let t = type as? _AnySQLEnumArray.Type else { fallthrough }
            if let st = t.elementType as? Schemable.Type {
                return .customArray(st.schemaName + "." + t.name)
            } else {
                return .customArray(t.name)
            }
            
        case is Optional<[Encodable]>.Type: fallthrough
        case is [Encodable].Type: return .jsonbArray
        
        case is ClosedRange<Date>.Type: return .daterange
        case is Range<Date>.Type: return .daterange
        
        default: return .text
        }
    }
}
fileprivate protocol AnyOptionalEnum {
    static var name: String { get }
}
extension Optional: AnyOptionalEnum where Wrapped: AnySQLEnum {
    fileprivate static var name: String { return Wrapped.name }
}
extension Optional {
    fileprivate static var trololo: Wrapped.Type { return Wrapped.self }
}
fileprivate protocol AnyOptionalEnumArray {
    static var name: String { get }
}
extension Array: AnyOptionalEnumArray where Element: AnyOptionalEnum {
    fileprivate static var name: String { Element.name }
}
fileprivate protocol _AnySQLEnumArray {
    static var name: String { get }
    static var elementType: AnySQLEnum.Type { get }
}
extension Array: _AnySQLEnumArray where Element: AnySQLEnum {
    fileprivate static var name: String { Element.name }
    fileprivate static var elementType: AnySQLEnum.Type { Element.self }
}