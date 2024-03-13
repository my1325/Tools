////
////  main.swift
////  Tools
////
////  Created by mayong on 2023/2/2.
////
//
import Commander
import Foundation
import PathKit

Group {
    $0.command("assets") { (filePath: String, newName: String) in
        let path = Path(filePath)
        let assetsTool = AssetsTool(path: path)
        try assetsTool?(.rename(newName))
    }
    
    $0.command("files") { (filePath: String, dest: String, rpx: String?) in
        let path = Path(filePath)
        let filesTools = FilesTool(file: path)
        try filesTools?(.extractFiles(destPath: Path(dest), rpx: rpx ?? ""))
    }
    
    $0.command("rename") { (filePath: String, rpx: String, replacement: String) in
        let path = Path(filePath)
        let filesTools = FilesTool(file: path)
        try filesTools?(.rename(rpx: rpx, replacement: replacement))
    }
    
    $0.command("unarchive") { (filePath: String, destPath: String, password: String?) in
        let path = Path(filePath)
        let filesTools = FilesTool(file: path)
        try filesTools?(.unarchive(destPath: Path(destPath), password: password))
    }
    
    $0.command("archive") { (filePath: String, destPath: String, password: String?) in
        let path = Path(filePath)
        let filesTools = FilesTool(file: path)
        try filesTools?(.unarchive(destPath: Path(destPath), password: password))
    }
    
    $0.command("replace") { (filePath: String, rpx: String, replacement: String) in
        let path = Path(filePath)
        let filesTools = FilesTool(file: path)
        try filesTools?(.replace(rpx: rpx, replacement: replacement))
    }
}.run()
