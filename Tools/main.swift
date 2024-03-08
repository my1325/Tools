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
// import MacroExamplesInterface

//let codeDir = "/Users/mayong/Desktop/wudi/JKNote/JokyNote/NKJYPrograme"
//let filesTool = FilesTool(file: FilePath(codeDir))
//try filesTool?(.extractFiles(destPath: FilePath("/Users/mayong/Desktop/wudi/JKNote/JokyNote/NKJY_Code"), rpx: ".*\\.swift"))
//let filesTool = FilesTool(file: FilePath("/Users/mayong/Desktop/wudi/JKNote/JokyNote/NKJY_Code"))
//try filesTool?(.rename(rpx: "JKN_", replacement: "NKJY_"))
//Group {
//    $0.command("assets") { (filePath: String, newName: String) in
//        let path = FilePath(filePath)
//        let assetsTool = AssetsTool(path: path)
//        try assetsTool?(.rename(newName))
//    }
//    
//    $0.command("files") { (filePath: String, dest: String, rpx: String?) in
//        let path = FilePath(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.extractFiles(destPath: FilePath(dest), rpx: rpx ?? ""))
//    }
//    
//    $0.command("refiles") { (filePath: String, rpx: String, replacement: String) in
//        let path = FilePath(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.rename(rpx: rpx, replacement: replacement))
//    }
//}.run()

//let dirPath = "/Users/mayong/Desktop/wudi/JKNote/NKJYPrograme"

//let filesTool = FilesTool(file: dirPath)
////try filesTool?(.rename(rpx: "JKN_", replacement: "NKJY_"))
//try filesTool?(.fileBuilderRun)

//let file = "/Users/mayong/Desktop/JKFDHSWCDXSMainWebController.swift"
//let tool = FilesTool(file: file)
//try tool?(.replace(rpx: "yyds_", replacement: "bf_"))

let dir = "/Users/mayong/Desktop/wudi/DSTimeline/DSTimeline/assetsFilesBuilder.yaml"
let assets = "/Users/mayong/Desktop/wudi/DSTimeline/DSTimeline/DSTimeline/Resources/Assets.xcassets"
let assetsTool = AssetsTool(path: Path(assets))
try assetsTool?(.buildAssetsStringFile(configPath: dir))
//try AssetsFileBuilder.install(Path(dir))
