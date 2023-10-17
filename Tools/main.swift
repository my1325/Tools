//
//  main.swift
//  Tools
//
//  Created by mayong on 2023/2/2.
//

import Commander
import CryptoSwift
import FilePath
import Foundation

let arguments = CommandLine.arguments

let key = "asjdlfjasdlkfaqw"
let iv = "alsjflkasdjflkaq"

let aes = try AESCoder(key: key, iv: iv)

func save(_ content: String, toNewPath newPath: FilePath? = nil, relativePath: FilePath) throws {
    var _newPath: FilePath
    if let newPath {
        _newPath = newPath
    } else {
        let pathExtension = relativePath.pathExtension
        let fileName = relativePath.lastPathConponent.replacingOccurrences(of: pathExtension, with: "")
        _newPath = relativePath.parent.appendFileName(String(format: "%@_new.%@", fileName, pathExtension)) as! FilePath
    }
    
    try _newPath.createIfNotExists()
    if let data = content.data(using: .utf8) {
        try _newPath.writeData(data)
        print("write encrypt \(_newPath.path) success")
    } else {
        print("write \(_newPath.path) failed")
    }
}

struct Keys {
    static let stringsOriginalKey = "original"
    static let stringsEncryptKey = "encrypt"
}

enum StringOuputType {
    case plist
    case xlsx
}

func handleStringsFile(_ filePath: [FilePath], output: StringOuputType, toPath: FilePath) throws {
    
}

func handleStringLines(_ filePath: FilePath) throws -> [String: [String: String]] {
    guard filePath.pathExtension == "strings" else {
        fatalError("can not handle file \(filePath.path)")
    }
    var retValue: [String: [String: String]] = [:]
    try filePath.readLines()
        .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        .filter({ !$0.isEmpty })
        .forEach({
            let cacheKey = $0.hasPrefix("//") ? Keys.stringsOriginalKey : Keys.stringsEncryptKey
            let components = $0.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].replacingOccurrences(of: "//", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\";")))
                var keyCache = retValue[key] ?? [:]
                keyCache[cacheKey] = value
                retValue[key] = keyCache
            }
        })
    return retValue
}

func handleStringsFile(_ filePath: [FilePath], toPlist newPath: FilePath) throws {
    var retCache: [String: [String: [String: String]]] = [:]
    for path in filePath {
        guard path.pathExtension == "strings" else { continue }
        let pathName = path.lastPathConponent.replacingOccurrences(of: "strings", with: "")
        let cache = try handleStringLines(path)
        for (key, values) in cache {
            var keyCache = retCache[key] ?? [:]
            keyCache[pathName] = values
            retCache[key] = keyCache
        }
    }
    try newPath.createIfNotExists()
    let encoder = PropertyListEncoder()
    let data = try encoder.encode(retCache)
    try newPath.writeData(data)
}

let cammand = command { (values: [String], parser: ArgumentParser) in
    if parser.hasOption("d") {
        let decryptValues = try aes.decrypt(values)
            .map { $0 ?? "nil" }
            .joined(separator: "\n")

        print(decryptValues)
    }

    if parser.hasOption("e") {
        let encryptValues = try aes.encrypt(values)
            .map { $0 ?? "nil" }
            .joined(separator: "\n")

        print(encryptValues)
    }

    if parser.hasOption("f"),
       let filePath = values.first,
       let path = Path.instanceOfPath(filePath) as? FilePath,
       path.pathExtension == "strings"
    {
        let encryptContent = try path.readLines()
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ $0.hasPrefix("//") })
            .map({
                let components = $0.components(separatedBy: "=")
                let key = components[0].replacingOccurrences(of: "//", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let value = try aes.encrypt(components[1].trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\";"))))
                let encryptValue = String(format: "%@ = \"%@\";", key, value)
                return [$0, encryptValue].joined(separator: "\n")
            })
            .joined(separator: "\n\n")
        
        try save(encryptContent, relativePath: path)
    }
}

cammand.run()
