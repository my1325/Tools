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
    
    var filesWithOutDirectory: [Path] {
        get throws {
            guard file.isDirectory else { return [file] }
            return try file.recursiveChildren().filter(\.isFile)
        }
    }
    
    enum Operation {
        case extractFiles(destPath: Path, rpx: String)
        case rename(rpx: String, replacement: String)
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
        case let .unarchive(destPath, password):
            try unarchive(destPath, password: password)
        case let .archive(destPath, password):
            archive(destPath, password: password)
        case let .replace(rpx, replacement):
            try replace(rpx, replacement: replacement)
        }
    }
    
    func replace(_ rpxString: String, replacement: String?) throws {
        guard let replacement else { return }
        let filePath: [Path] = try filesWithOutDirectory
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
    
    func rename(_ rpxString: String, replacement: String?) throws {
        guard let replacement else { return }
        
        let files = try filesWithOutDirectory
        let rpx = try NSRegularExpression(pattern: rpxString, options: .caseInsensitive)
        for file in files {
            let filename = file.lastComponent
            guard let range = filename.nsRangeForSubString(filename) else { continue }
            let newFilename = rpx.stringByReplacingMatches(in: filename, options: .reportCompletion, range: range, withTemplate: replacement)
            print("renaming \(filename) to \(newFilename)")
            _ = try file.rename(newFilename)
        }
    }
    
    func extractFilesToDest(_ destPath: Path, rpxString: String?) throws {
        let files = try filesWithOutDirectory
        var matchFiles: [Path] = files
        if let rpxString, !rpxString.isEmpty {
            matchFiles = files.filter({ $0.match(rpxString) })
        }
        try matchFiles.forEach {
            let dest = destPath + $0.lastComponent
            print("coping \($0.lastComponent) to \(dest)")
            try $0.copy(dest)
        }
    }
}
