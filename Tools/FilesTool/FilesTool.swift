//
//  FilesTool.swift
//  ToolBox
//
//  Created by mayong on 2024/2/23.
//

import Foundation
import PathKit
import Yams
import ZipArchive

struct FilesTool {
    let file: Path
    init?(file: Path) {
        self.file = file
    }
    
    init?(file: String) {
        self.init(file: Path(file))
    }
    
    enum Operation {
        case extractFiles(destPath: Path, rpx: String)
        case rename(rpx: String, replacement: String)
        case fileBuilderInit
        case fileBuilderRun
        case unarchive(destPath: Path, password: String?)
        case archive(destPath: Path, password: String?)
        case replace(rpx: String, replacement: String)
    }
    
    func callAsFunction(_ op: Operation) throws {
        switch op {
        case let .extractFiles(dest, rpx):
            try extractFilesToDest(dest, rpxString: rpx)
        case let .rename(rpx, replacement):
            try rename(rpx, replacement: replacement)
        case .fileBuilderInit:
            try fileBuilderInit(file)
        case .fileBuilderRun:
            try fileBuilderRun(file)
        case let .unarchive(destPath, password):
            try unarchive(destPath, password: password)
        case let .archive(destPath, password):
            archive(destPath, password: password)
        case let .replace(rpx, replacement):
            try replace(rpx, replacement: replacement)
        }
    }
    
    func replace(_ rpxString: String, replacement: String) throws {
        let filePath: [Path]
        if file.isFile { filePath = [file] }
        else {
            filePath = try file.recursiveChildren().filter(\.isFile)
        }
        
        let rpx = try NSRegularExpression(pattern: rpxString, options: [])
        for file in filePath {
            print("repacing \(file.lastComponent)")
            let content = NSMutableString(string: try file.read(.utf8))
            rpx.replaceMatches(in: content, options: .reportCompletion, range: content.range(of: content as String), withTemplate: replacement)
            try file.write(content as String, encoding: .utf8)
        }
    }
    
    func unarchive(_ destPath: Path, password: String?) throws {
        try SSZipArchive.unzipFile(atPath: file.string, toDestination: destPath.string, overwrite: true, password: password)
    }
    
    func archive(_ destPath: Path, password: String?) {
        SSZipArchive.createZipFile(atPath: destPath.string, withContentsOfDirectory: file.string, withPassword: password)
    }
    
    func rename(_ rpxString: String, replacement: String) throws {
        let files = try file.recursiveChildren().filter(\.isFile)
        let rpx = try NSRegularExpression(pattern: rpxString, options: .caseInsensitive)
        for file in files {
            let filename = file.lastComponent
            guard let range = filename.nsRangeForSubString(filename) else { continue }
            let newFilename = rpx.stringByReplacingMatches(in: filename, options: .reportCompletion, range: range, withTemplate: replacement)
            print("renaming \(filename) to \(newFilename)")
            _ = try file.rename(newFilename)
        }
    }
    
    func extractFilesToDest(_ destPath: Path, rpxString: String) throws {
        let files = try file.recursiveChildren().filter(\.isFile)
        var matchFiles: [Path] = files
        if !rpxString.isEmpty {
//            let predicate = NSPredicate(format: "SELF MATCHES %@", rpxString)
            matchFiles = files.filter({ $0.match(rpxString) })
        }
        try matchFiles.forEach {
            let dest = destPath + $0.lastComponent
            print("coping \($0.lastComponent) to \(dest)")
            try $0.copy(dest)
        }
    }
    
    func fileBuilderInit(_ path: Path) throws {
        let yamlEncoder = YAMLEncoder()
        yamlEncoder.options = .init()
        let initContent = try yamlEncoder.encode(ImageFileBuilderConfig())
        let pathFile: Path
        if path.isFile {
            pathFile = path
        } else {
            pathFile = path + "file_builder.yaml"
        }
        try pathFile.write(initContent, encoding: .utf8)
    }
    
    func fileBuilderRun(_ path: Path) throws {
        let pathFile: Path
        if path.isFile {
            pathFile = path
        } else {
            pathFile = path + "file_builder.yaml"
        }
        let yamlData = try pathFile.read()
        let yamlDecoder = YAMLDecoder(encoding: .utf8)
        let config = try yamlDecoder.decode(ImageFileBuilderConfig.self, from: yamlData)
        let builder = ImageFileBuilder(config: config)
        try builder.build()
    }
}
