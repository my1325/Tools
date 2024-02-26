//
//  Array+Extensions.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation

extension Array where Element: Hashable {
    func removeDuplicates() -> Self {
        Array(Set(self))
    }
}
