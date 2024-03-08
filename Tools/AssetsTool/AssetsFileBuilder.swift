//
//  AssetsFileBuilder.swift
//  ToolBox
//
//  Created by mayong on 2024/2/28.
//

import Foundation
import PathKit
import Yams

struct AssetsFileBuilderConfig: Codable {
    enum Language: String, Codable {
        case swift = "Swift"
        case oc = "Objective-C"
        
        var fileExtensions: String {
            switch self {
            case .swift: "swift"
            case .oc: ".h"
            }
        }
    }
    
    let prefix: String
//    let input: String
    let output: String
    let language: Language
//    let snakeCase: Bool
    
    init(
        prefix: String = "",
        input: String = "",
        output: String = "",
        language: Language = .swift,
        snakeCase: Bool = true)
    {
        self.prefix = prefix
//        self.input = input
        self.output = output
        self.language = language
//        self.snakeCase = snakeCase
    }
}

internal final class AssetsFileBuilder {
    let config: AssetsFileBuilderConfig
    let assetsDir: Path
    init(_ assetsDir: Path, config: AssetsFileBuilderConfig) {
        self.assetsDir = assetsDir
        self.config = config
    }
    
    static func install(_ workDir: Path) throws {
        let newConfig = AssetsFileBuilderConfig()
        let yamlEncoder = YAMLEncoder()
        let data = try yamlEncoder.encode(newConfig)
        if workDir.isFile {
            try workDir.write(data)
        } else {
            let file = workDir + "assetsFilesBuilder.yaml"
            try file.write(data)
        }
    }
    
    func build() throws {
        switch config.language {
        case .swift: try buildSwift()
        case .oc: try buildOC()
        }
    }
    
    private func buildSwift() throws {
        let content = try foreach
            .map {
                String(format: "let %@%@ = \"%@\"", config.prefix, $0.snakeCase, $0)
            }
            .joined(separator: "\r\n\r\n")
        try writeContent(content)
    }
    
    private func buildOC() throws {
        let content = try foreach
            .map {
                String(format: "static NSString * const %@%@ = @\"%@\";", config.prefix, $0.snakeCase, $0)
            }
            .joined(separator: "\r\n\r\n")
        try writeContent(content)
    }
    
    private func writeContent(_ content: String) throws {
        var file: Path = Path(config.output)
        if file.isDirectory {
            file = file + "AssetsFile.\(config.language.fileExtensions)"
        }
        try file.write(content)
    }
    
    var foreach: [String] {
        get throws {
            try assetsDir.recursiveChildren()
                .lazy
                .filter({ $0.extension == "imageset" })
                .map(\.lastComponentWithoutExtension)
        }
    }
}
