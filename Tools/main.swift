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

// Group {
//    $0.command("assets") { (filePath: String, newName: String) in
//        let path = Path(filePath)
//        let assetsTool = AssetsTool(path: path)
//        try assetsTool?(.rename(newName))
//    }
//
//    $0.command("files") { (filePath: String, dest: String, rpx: String?) in
//        let path = Path(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.extractFiles(destPath: Path(dest), rpx: rpx ?? ""))
//    }
//
//    $0.command("rename") { (filePath: String, rpx: String, replacement: String) in
//        let path = Path(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.rename(rpx: rpx, replacement: replacement))
//    }
//
//    $0.command("unzip") { (filePath: String, destPath: String, password: String?) in
//        let path = Path(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.unarchive(destPath: Path(destPath), password: password))
//    }
//
//    $0.command("zip") { (filePath: String, destPath: String, password: String?) in
//        let path = Path(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.unarchive(destPath: Path(destPath), password: password))
//    }
//
//    $0.command("replace") { (filePath: String, rpx: String, replacement: String) in
//        let path = Path(filePath)
//        let filesTools = FilesTool(file: path)
//        try filesTools?(.replace(rpx: rpx, replacement: replacement))
//    }
// }.run()

// let path = "/Users/mayong/Desktop/wudi/FstWear/FstWear/Main/multibeam/assets/FstWAbcdefMC_MultiBeamResource"
// let dstkPath = "/Users/mayong/Desktop/wudi/FstWear/FstWear/Main/multibeam/assets/FstWAbcdefMC_MultiBeamResource.zip"

// let path = "/Users/mayong/Desktop/wudi/Lottie/Lottie/Lottie/LiveAbout/LiveSource/assets/MlatBF_Resources"
// let path = "/Users/mayong/Desktop/wudi/GYLive/files/Ycat_LiveIcon"
// let dstkPath = "\(path).zip"
// let fileTool = FilesTool(file: Path(path))
// fileTool?.archive(Path(dstkPath), password: "bBq.123")

// func newStringFile(_ file: Path) throws {
//    let string: String = try file.read()
//    let newContent = string.components(separatedBy: "\n")
//        .filter({ $0.hasPrefix("//") })
//        .map({
//            let startIndex = $0.startIndex
//            let endIndex = $0.index($0.startIndex, offsetBy: 1)
//            return $0.replacingCharacters(in: startIndex ... endIndex, with: "")
//        })
//        .joined(separator: "\n\n")
//    try file.write(newContent, encoding: .utf8)
// }
//
// func handleStringsFile(_ dir: Path) throws {
//    for lprojDir in dir {
//        for stringFile in lprojDir {
//            try newStringFile(stringFile)
//        }
//    }
// }
//
// try handleStringsFile(Path("/Users/mayong/Desktop/wudi/FstWear/FstWear/Main/FstWAbcdef_Resources/Localized"))

import AppKit
import CryptoSwift

// let aes = try AES(key: "qwertyasdf123456", iv: "mnbvcxzlkjhyuiop")
//
////let path = Path("/Users/mayong/Desktop/Const/account_api.plist")
// let path = Path("/Users/mayong/Desktop/Const/system_api.plist")
//
// let data = try Data(contentsOf: path.url)
// guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
//    throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "invalid"])
// }
//
// let values = try plist
//    .compactMap({ Data(base64Encoded: $1) })
//    .map({ try aes.decrypt($0.bytes) })
//    .map({ Data($0) })
//    .compactMap({ String(data: $0, encoding: .utf8) })
//    .joined(separator: "\n")
//
// let newPath = path.parent() + "\(path.lastComponentWithoutExtension)"
// print(newPath)
// try newPath.write(values)

let data = "123456"
let keyData = "1111111111111111"
let ivData = "2222222222222222"
do {
    let blockMode: CCC_AESBlockMode = .CCC_CBC(ccc_iv: ivData)
    let aesCryptor = try CCC_Crypt.ccc_AES(keyData, ccc_blockMode: blockMode)
    
    let result = try aesCryptor.ccc_encrypt(data)
    let base64String = result.ccc_base64EncodedString
    
    let dataToDecrypt = Data(base64Encoded: base64String)!
    let decryptData = try aesCryptor.ccc_decrypt(dataToDecrypt)
    
    let decryptString = decryptData.ccc_utf8EncodedString
    
    print("\(base64String)  \(decryptString) \(decryptString == "123456")")
} catch {
    print(error)
}

do {
    let aes = try AES(key: keyData.ccc_byteData, blockMode: CBC(iv: ivData.ccc_byteData), padding: .pkcs7)
    let result = try aes.encrypt(data.ccc_byteData)
    
    let base64String = Data(result).base64EncodedString()
    let dataToDecrypt = Data(base64Encoded: base64String)!
    let decryptData = try aes.decrypt(Array(dataToDecrypt))
    let decryptString = String(data: Data(decryptData), encoding: .utf8)
    
    print("\(base64String)  \(decryptString) \(decryptString == "123456")")

} catch {
    print(error)
}

print("adfasdfasdf")
