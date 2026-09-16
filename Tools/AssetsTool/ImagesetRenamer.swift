//
//  ImageAssetsResolver.swift
//  ToolBox
//
//  Created by mayong on 2024/2/19.
//

import Foundation
import PathKit

public final class ImagesetReplacer {

    let rpx: String
    let replacement: String
    init(rpx: String, replacement: String) {
        self.rpx = rpx
        self.replacement = replacement
    }
    
    @discardableResult
    func callAsFunction(_ imageset: Imageset) throws -> Imageset {
        try replaced(imageset)
    }
    
    @discardableResult
    func replaced(_ imageset: Imageset) throws -> Imageset {
        let file = imageset.file
        let newContent = try replaced(imageset.content, in: file)
        let newSet = Imageset(file: file, content: newContent)
        try newSet.writeContent()
        return newSet
    }
    
    @discardableResult
    func replaced(_ content: ImagesetContent, in file: Path) throws -> ImagesetContent {
        let newImeges = try content.images.map({ try replaced($0, in: file) })
        return .init(images: newImeges, info: content.info)
    }
    
    @discardableResult
    func replaced(_ image: ImagesetContent.Image, in file: Path) throws -> ImagesetContent.Image {
        guard let filename = image.filename, !filename.isEmpty else { return image }
        let imageFile = file + filename
        let newName = imageFile.lastComponent.replacingOccurrences(of: rpx, with: replacement)
        _ = try imageFile.rename(newName)
        return image.new(filename: newName)
    }	
}

public final class ImagesetRenamer {
    
    let newName: String
    init(newName: String) {
        self.newName = newName
    }
    
    @discardableResult
    func callAsFunction(_ imageset: Imageset) throws -> Imageset {
        try renamed(imageset)
    }
    
    private func newNameInFile(_ file: Path) -> String {
        newName.isEmpty ? file.lastComponentWithoutExtension : newName
    }
    
    @discardableResult
    func renamed(_ imageset: Imageset) throws -> Imageset {
        let file = imageset.file
        let newContent = try renamed(imageset.content, in: file)
        let newFile = try file.rename(String(format: "%@.imageset", newNameInFile(file)))
        let newSet = Imageset(file: newFile, content: newContent)
        try newSet.writeContent()
        return newSet
    }
    
    @discardableResult
    func renamed(_ content: ImagesetContent, in file: Path) throws -> ImagesetContent {
        let newImeges = try content.images.map({ try renamed($0, in: file) })
        return .init(images: newImeges, info: content.info)
    }
    
    @discardableResult
    func renamed(_ image: ImagesetContent.Image, in file: Path) throws -> ImagesetContent.Image {
        guard let filename = image.filename, !filename.isEmpty else { return image }
        let imageFile = file + filename
        let newName = String(format: "%@@%@.%@", newNameInFile(file), image.scale, imageFile.extension ?? "")
        _ = try imageFile.rename(newName)
        return image.new(filename: newName)
    }
}
