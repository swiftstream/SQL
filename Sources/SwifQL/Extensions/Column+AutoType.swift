//
//  Column+AutoType.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

extension Column {
    struct AutoType {
        let type: Type
        let isOptional: Bool
        
        init (_ type: Type, _ isOptional: Bool) {
            self.type = type
            self.isOptional = isOptional
        }
    }
    
    static func autoType(_ constraints: [Constraint]) -> AutoType {
        var isOptional = false
        switch Value.self {
        case is Optional<String>.Type: isOptional = true; fallthrough
        case is String.Type: return .init(.text, isOptional)
        
        case is Optional<[String]>.Type: isOptional = true; fallthrough
        case is [String].Type: return .init(.textArray, isOptional)
        
        case is Optional<UUID>.Type: isOptional = true; fallthrough
        case is UUID.Type: return .init(.uuid, isOptional)
        
        case is Optional<[UUID]>.Type: isOptional = true; fallthrough
        case is [UUID].Type: return .init(.uuidArray, isOptional)
        
        case is Optional<Double>.Type: isOptional = true; fallthrough
        case is Double.Type: return .init(.decimal, isOptional)
        
        case is Optional<[Double]>.Type: isOptional = true; fallthrough
        case is [Double].Type: return .init(.decimalArray, isOptional)
        
        case is Optional<Float>.Type: isOptional = true; fallthrough
        case is Float.Type: return .init(.float4, isOptional)
        
        case is Optional<[Float]>.Type: isOptional = true; fallthrough
        case is [Float].Type: return .init(.float4Array, isOptional)
        
        case is Optional<UInt>.Type: isOptional = true; fallthrough
        case is UInt.Type: fallthrough
        
        case is Optional<UInt8>.Type: isOptional = true; fallthrough
        case is UInt8.Type: fallthrough
        
        case is Optional<UInt16>.Type: isOptional = true; fallthrough
        case is UInt16.Type: fallthrough
        
        case is Optional<UInt32>.Type: isOptional = true; fallthrough
        case is UInt32.Type: fallthrough
        
        case is Optional<UInt64>.Type: isOptional = true; fallthrough
        case is UInt64.Type: return .init(.int, isOptional)
        
        case is Optional<[UInt]>.Type: isOptional = true; fallthrough
        case is [UInt].Type: fallthrough
        
        case is Optional<[UInt8]>.Type: isOptional = true; fallthrough
        case is [UInt8].Type: fallthrough
        
        case is Optional<[UInt16]>.Type: isOptional = true; fallthrough
        case is [UInt16].Type: fallthrough
        
        case is Optional<[UInt32]>.Type: isOptional = true; fallthrough
        case is [UInt32].Type: fallthrough
        
        case is Optional<[UInt64]>.Type: isOptional = true; fallthrough
        case is [UInt64].Type: return .init(.intArray, isOptional)
        
        case is Optional<Int8>.Type: isOptional = true; fallthrough
        case is Int8.Type: fallthrough
        
        case is Optional<Int16>.Type: isOptional = true; fallthrough
        case is Int16.Type: fallthrough
        
        case is Optional<Int32>.Type: isOptional = true; fallthrough
        case is Int32.Type: fallthrough
        
        case is Optional<Int>.Type: isOptional = true; fallthrough
        case is Int.Type:
            if constraints.contains(where: { $0.isPrimaryKey }) {
                return .init(.serial, isOptional)
            } else {
                return .init(.int, isOptional)
            }
        
        case is Optional<Int64>.Type: isOptional = true; fallthrough
        case is Int64.Type:
            if constraints.contains(where: { $0.isPrimaryKey }) {
                return .init(.bigserial, isOptional)
            } else {
                return .init(.bigint, isOptional)
            }
        
        case is Optional<[Int8]>.Type: isOptional = true; fallthrough
        case is [Int8].Type: fallthrough
        
        case is Optional<[Int16]>.Type: isOptional = true; fallthrough
        case is [Int16].Type: fallthrough
        
        case is Optional<[Int32]>.Type: isOptional = true; fallthrough
        case is [Int32].Type: fallthrough
        
        case is Optional<[Int]>.Type: isOptional = true; fallthrough
        case is [Int].Type: return .init(.intArray, isOptional)
        
        case is Optional<[Int64]>.Type: isOptional = true; fallthrough
        case is [Int64].Type: return .init(.bigintArray, isOptional)

        case is Optional<PureDate>.Type: isOptional = true; fallthrough
        case is PureDate.Type: return .init(.date, isOptional)

        case is Optional<PureTime>.Type: isOptional = true; fallthrough
        case is PureTime.Type: return .init(.time, isOptional)
        
        case is Optional<Date>.Type: isOptional = true; fallthrough
        case is Date.Type: return .init(.timestamptz, isOptional)
        
        case is Optional<[Date]>.Type: isOptional = true; fallthrough
        case is [Date].Type: return .init(.timestamptzArray, isOptional)
        
        case is Optional<Data>.Type: isOptional = true; fallthrough
        case is Data.Type: return .init(.bytea, isOptional)
        
        case is Optional<[Data]>.Type: isOptional = true; fallthrough
        case is [Data].Type: return .init(.byteaArray, isOptional)
            
        case is AnyOptionalEnum.Type:
            guard let t = Value.self as? AnyOptionalEnum.Type else { fallthrough }
            return .init(.custom(t.name), true)
        case is AnySQLEnum.Type:
            guard let t = Value.self as? AnySQLEnum.Type else { fallthrough }
            return .init(.custom(t.name), false)
        
        case is Optional<[Encodable]>.Type: isOptional = true; fallthrough
        case is [Encodable].Type: return .init(.jsonbArray, isOptional)
        
        case is ClosedRange<Date>.Type: return .init(.daterange, isOptional)
        case is Range<Date>.Type: return .init(.daterange, isOptional)
        
        default: return .init(.text, true)
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
