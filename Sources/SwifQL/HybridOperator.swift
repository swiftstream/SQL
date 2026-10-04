//
//  HybridOperator.swift
//  
//
//  Created by TierraCero on 5/30/23.
//

import Foundation

extension SQLHybridOperator {
    
    public typealias HybridResult = SQLHybridOperator
    
    public static var random: HybridResult {
        .init("random()".operator, "rand()".operator, "random()".operator)
    }
    
    private func concatWith(_ hybrid: HybridResult) -> HybridResult {
        return hybrid
    }
}
extension String {
    fileprivate var `operator`: SQLPartOperator { .init(self) }
}
