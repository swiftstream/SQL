//
//  IndexItem.swift
//  SwifQL
//
//  Created by Mihael Isaev on 18.08.2020.
//

public class IndexItem: SQLable {
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        switch item {
        case .column(let name):
            parts.append(SQLPartColumn(name))
        case .expression(let expression):
            parts.append(o: .openBracket)
            parts.append(contentsOf: expression.parts)
            parts.append(o: .closeBracket)
        }
        if order.parts.count > 0 {
            parts.append(o: .space)
            parts.append(contentsOf: order.parts)
        }
        return parts
    }
    
    public enum Order: SQLable {
        public var parts: [SQLPart] {
            var parts: [SQLPart] = []
            switch self {
            case .asc: break
            case .ascNullsFirst:
                parts.append(o: .nulls)
                parts.append(o: .space)
                parts.append(o: .first)
            case .desc:
                parts.append(o: .desc)
            case .descNullsLast:
                parts.append(o: .desc)
                parts.append(o: .space)
                parts.append(o: .nulls)
                parts.append(o: .space)
                parts.append(o: .last)
            }
            return parts
        }
        
        case asc, ascNullsFirst, desc, descNullsLast
    }
    
    public enum Item {
        case column(String)
        case expression(SQLable)
    }
    
    let order: Order
    let item: Item
    
    public init (item: Item, order: Order) {
        self.item = item
        self.order = order
    }
    
    public static func column(_ column: String, order: Order = .asc) -> IndexItem {
        .init(item: .column(column), order: order)
    }
    
    public static func expression(_ expression: SQLable, order: Order = .asc) -> IndexItem {
        .init(item: .expression(expression), order: order)
    }
}
