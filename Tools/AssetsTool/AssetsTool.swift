//
//  AssetsTool.swift
//  Tools
//
//  Created by mayong on 2024/1/10.
//

import Foundation
import PathKit
import Yams

struct AssetsTool {
    
    let path: Path
    init?(path: Path) {
        guard path.isDirectory, path.extension == "xcassets" else { return nil }
        self.path = path
    }
    
    enum Operation {
        case rename(String)
    }
    
    func callAsFunction(_ op: Operation) throws {
        switch op {
        case let .rename(newName):
            try resolveImagesetsName(newName)
        }
    }
    
    func resolveImagesetsName(_ newName: String) throws {
        let imagesets = try path.recursiveChildren().compactMap({ try Imageset(file: $0) })
        for imageset in imagesets  {
            let renamer = ImagesetRenamer(newName: newName)
            print("renaming \(imageset.file.lastComponent) to \(newName)")
            try renamer(imageset)
        }
    }
}


