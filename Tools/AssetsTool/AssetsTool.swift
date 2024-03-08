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
        case buildAssetsStringFile(configPath: String)
    }
    
    func callAsFunction(_ op: Operation) throws {
        switch op {
        case let .rename(newName):
            try resolveImagesetsName(newName)
        case let .buildAssetsStringFile(configPath):
            try buildAssetsStringFile(configPath)
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
    
    func buildAssetsStringFile(_ configPath: String) throws {
        let path = Path(configPath)
        let data = try path.read()
        let yamlDecoder = YAMLDecoder()
        let config = try yamlDecoder.decode(AssetsFileBuilderConfig.self, from: data)
        let builder = AssetsFileBuilder(self.path, config: config)
        try builder.build()
    }
}


