//
//  Array+Extensions.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation

precedencegroup ArraySubscriptionPrecedenceGroup {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
}

infix operator ?? : ArraySubscriptionPrecedenceGroup

extension Array where Element: Hashable {
    func removeDuplicates() -> Self {
        Array(Set(self))
    }
    
    static func ??(_ lhs: Self, _ rhs: Int) -> Element? {
        if rhs < lhs.count {
            return lhs[rhs]
        }
        return nil
    }
}
