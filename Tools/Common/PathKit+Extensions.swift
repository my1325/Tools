//
//  PathKit+Extensions.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation
import PathKit

extension Path {
    @discardableResult
    func rename(_ newName: String) throws -> Path {
        guard self.lastComponent != newName else { return self }
        let newPath = self.parent() + newName
        if exists, !newPath.exists {
            try self.copy(newPath)
        }
        return newPath
    }
    
    func copy(_ dest: Path) throws {
        let fileManager = FileManager.default
        try fileManager.copyItem(atPath: self.string, toPath: dest.string)
    }
}
