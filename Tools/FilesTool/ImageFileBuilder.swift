//
//  ImageFileTemplate.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation
import PathKit

struct ImageFileBuilderConfig: Codable {
    let bundle: String
    
    let prefix: String
    
    let input: String
    
    let output: String
    
    let filter: String
    
    let className: String
    
    let swiftUIEnable: Bool
    
    let uiImageEnable: Bool
    
    init(
        bundle: String = "",
        prefix: String = "",
        input: String = "",
        output: String = "",
        filter: String = "*.png",
        className: String = "",
        swiftUIEnable: Bool = true,
        uiImageEnable: Bool = true)
    {
        self.bundle = bundle
        self.prefix = prefix
        self.input = input
        self.output = output
        self.filter = filter
        self.className = className
        self.swiftUIEnable = swiftUIEnable
        self.uiImageEnable = uiImageEnable
    }
    
    var bundleToken: String {
        guard bundle.isEmpty else { return bundle }
        return "Bundle.\(prefix)imageFile"
    }
    
    var outputFile: Path {
        let path = Path(output)
        if path.isFile {
            return path
        }
        
        return path + "\(prefix.uppercased())ImageFiles.swift"
    }
    
    var classToken: String {
        guard className.isEmpty else { return className }
        return "ImageFile"
    }
}

internal final class ImageFileBuilder {
    let config: ImageFileBuilderConfig
    init(config: ImageFileBuilderConfig) {
        self.config = config
    }
    
    func build() throws {
        let instances = try buildInstances()
        let content = [
            buildBundle(),
            buildeClass(),
            buildSwiftUI(),
            buildUIImage(),
            instances
        ]
            .joined(separator: "\r\n\r\n")
        try config.outputFile.write(content, encoding: .utf8)
    }
    
    private func buildUIImage() -> String {
        guard config.uiImageEnable else { return "" }
        return """
        #if canImport(UIKit)
        import UIKit
        extension UIKit.UIImage {
        \tconvenience init?(_ \(config.prefix)file: \(config.prefix.uppercased())\(config.classToken)) {
        \t\tself.init(named: \(config.prefix)file.\(config.prefix)fileName, in: \(config.bundleToken), compatibleWith: nil)
        \t}
        }
        #endif
        """
    }
    
    private func buildSwiftUI() -> String {
        guard config.swiftUIEnable else { return "" }
        return """
        #if canImport(SwiftUI)
        import SwiftUI
        extension SwiftUI.Image {
            init(_ \(config.prefix)file: \(config.prefix.uppercased())\(config.classToken)) {
                if let \(config.prefix)uiImage = UIImage(\(config.prefix)file) {
                    self.init(uiImage: \(config.prefix)uiImage)
                } else {
                    self.init(\(config.prefix)file.\(config.prefix)fileName, bundle: \(config.bundleToken))
                }
            }
        }
        #endif
        """
    }
    
    private func buildBundle() -> String {
        guard config.bundle.isEmpty else { return "" }
        return """
        internal final class \(config.prefix.uppercased())BundleToken {}

        extension Bundle {
            static let \(config.prefix)imageFile: Bundle = Bundle(for: \(config.prefix.uppercased())BundleToken.self)
        }
        """
    }
    
    private func buildeClass() -> String {
        """
        internal final class \(config.prefix.uppercased())\(config.classToken) {
            let \(config.prefix)fileName: String
            init(_ \(config.prefix)fileName: String) {
                self.\(config.prefix)fileName = \(config.prefix)fileName
            }
        }
        """
    }
    
    private func buildInstances() throws -> String {
        """
        extension \(config.prefix.uppercased())\(config.classToken) {
        \(try Path(config.input).recursiveChildren()
            .filter { $0.match(config.filter) }
            .map { buildInstance($0.lastComponentWithoutExtension.withoutAtScale.withoutSpaceAndNewLine) }
            .removeDuplicates()
            .joined(separator: "\r\n\r\n"))
        }
        """
    }
    
    private func buildInstance(_ name: String) -> String {
        "\tstatic let \(config.prefix)\(name.snakeCase) = \(config.prefix.uppercased())\(config.classToken)(\"\(name)\")"
    }
}
