//
//  ImageAssets.swift
//  ToolBox
//
//  Created by mayong on 2024/2/20.
//

import Foundation
import PathKit

struct ImagesetContent: Codable {
    struct Image: Codable {
        let filename: String?
        let idiom: String?
        let scale: String
        
        init(filename: String?, idiom: String?, scale: String) {
            self.filename = filename
            self.idiom = idiom
            self.scale = scale
        }
        
        func new(filename: String? = nil, idiom: String? = nil, scale: String? = nil) -> Image {
            let newFilename = filename ?? self.filename
            let newIdiom = idiom ?? self.idiom
            let newScale = idiom ?? self.scale
            return Image(filename: newFilename, idiom: newIdiom, scale: newScale)
        }
    }
    
    let images: [Image]
    
    struct Info: Codable {
        let author: String
        let version: Int
    }
    
    let info: Info
    
    init(images: [Image], info: Info) {
        self.images = images
        self.info = info
    }
}

internal struct Imageset {
    let content: ImagesetContent
    let file: Path
    
    init?(file: Path) throws {
        guard file.isDirectory, file.extension == "imageset" else { return nil }
        let contentFile = file + "Contents.json"
        let data = try  contentFile.read()
        let jsonDecoder = JSONDecoder()
        self.content = try jsonDecoder.decode(ImagesetContent.self, from: data)
        self.file = file
    }
    
    init(file: Path, content: ImagesetContent) {
        self.file = file
        self.content = content
    }
    
    func writeContent(_ jsonEncoder: JSONEncoder = JSONEncoder()) throws {
        let contentFile = file + "Contents.json"
        let data = try jsonEncoder.encode(content)
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try contentFile.write(prettyData)
    }
}
