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
import CoreXLSX

let arguments = CommandLine.arguments

let key = "asjdlfjasdlkfaqw"
let iv = "alsjflkasdjflkaq"

let aes = try AESCoder(key: key, iv: iv)

// MARK: -  encrypt strings
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

// MARK: - Strings To Plist
enum StringOuputType {
    case plist
    case xlsx
}

func handleStringsFile(_ filePath: [DirectoryPath], output: StringOuputType, toPath: FilePath, isDocumentOrigin: Bool, includePrefix: String) throws {
    switch output {
    case .plist:
        try handleStringsFile(filePath, toPlist: toPath, isDocumentOrigin: isDocumentOrigin, includePrefix: includePrefix)
    case .xlsx:
        try handleStringsFile(filePath, toXLSX: toPath, isDocumentOrigin: isDocumentOrigin, includePrefix: includePrefix)
    }
}

func handleStringsFile(_ filePath: [DirectoryPath], toPlist newPath: FilePath, isDocumentOrigin: Bool, includePrefix: String) throws {
    var retCache: [String: [String: String]] = [:]
    for path in filePath {
        guard path.pathExtension == "lproj" else { continue }
        let pathName = path.lastPathConponent.replacingOccurrences(of: "lproj", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "./")))
        for file in path.directoryIterator() {
            guard let filePath = file as? FilePath, filePath.pathExtension == "strings" else {
                continue
            }
            let cache = try handleStringLines(filePath, isDocumentOrigin: isDocumentOrigin, includePrefix: includePrefix)
            for (key, values) in cache {
                var keyCache = retCache[pathName] ?? [:]
                keyCache[key] = values
                retCache[pathName] = keyCache
            }
        }
    }
    try newPath.createIfNotExists()
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    let data = try encoder.encode(retCache)
    try newPath.writeData(data)
}

func handleStringLines(_ filePath: FilePath, isDocumentOrigin: Bool, includePrefix: String) throws -> [String: String] {
    guard filePath.pathExtension == "strings" else {
        fatalError("can not handle file \(filePath.path)")
    }
    let lineFilter = { (line: String) -> Bool in
        guard !line.isEmpty else { return false }
        return (isDocumentOrigin && (line.hasPrefix("//") || !line.hasPrefix(String(format: "\"%@", includePrefix)))) ||
        (!isDocumentOrigin && !line.hasPrefix("//"))
    }
    var retValue: [String: String] = [:]
    try filePath.readLines()
        .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        .filter(lineFilter)
        .forEach({
            let components = $0.components(separatedBy: " = ")
            if components.count == 2 {
                let key = components[0]
                    .replacingOccurrences(of: "//", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\";")))
                
                let value = components[1]
                    .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\";")))
                if let value = retValue[key] {
                    print("repeat key \(key) value \(value)")
                }
                retValue[key] = value
                    
            } else {
                print("not handle line \($0)")
            }
        })
    return retValue
}

// MARK: - Plist To Strings
func handlePlistToStrings(_ plist: FilePath, name: String, output: DirectoryPath, includePrefix: String) throws {
    let retCache: [String: String] = try handlePlist(plist, includePrefix: includePrefix)
    for (key, value) in retCache {
        let keyDir = output.appendConponent(String(format: "%@.lproj", key))
        try keyDir.createIfNotExists()
        let filePath = keyDir.appendFileName(String(format: "%@.strings", name))
        try filePath.createIfNotExists()
        if let data = value.data(using: .utf8) {
            try filePath.writeData(data)
        }
    }
}

func handlePlist(_ plist: FilePath, includePrefix: String) throws -> [String: String] {
    var retValue: [String: [String]] = [:]
    let data = try plist.readData()
    let decoder = PropertyListDecoder()
    let cached = try decoder.decode([String: [String: String]].self, from: data)
    for (language, languageCached) in cached {
        for (key, value) in languageCached {
            var strings: [String] = Array(repeating: "", count: 2)
            strings[0] = String(format: "// \"%@\" = \"%@\";", key, value)
            if key.hasPrefix(includePrefix) {
                strings[1] = String(format: "\"%@\" = \"%@\";", key, try aes.encrypt(value))
            } else {
                strings[1] = String(format: "\"%@\" = \"%@\";", key, value)
            }
            let keyString = strings.joined(separator: "\n")
            var languageStrings = retValue[language] ?? []
            languageStrings.append(keyString)
            retValue[language] = languageStrings
        }
    }
    
    return retValue.mapValues({ $0.joined(separator: "\n\n") })
}

// MARK: - Strings To XLSX
// key, ar, tr, en
func handleStringsFile(_ file: [DirectoryPath], toXLSX newPath: FilePath, isDocumentOrigin: Bool, includePrefix: String) throws {
    var retCache: [String: [String: String]] = [:]
    for path in file {
        guard path.pathExtension == "lproj" else { continue }
        let pathName = path.lastPathConponent.replacingOccurrences(of: "lproj", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "./")))
        for file in path.directoryIterator() {
            guard let filePath = file as? FilePath, filePath.pathExtension == "strings" else {
                continue
            }
            let cache = try handleStringLines(filePath, isDocumentOrigin: isDocumentOrigin, includePrefix: includePrefix)
            for (key, values) in cache {
                var keyCache = retCache[key] ?? [:]
                keyCache[pathName] = values
                retCache[key] = keyCache
            }
        }
    }
//    
//    guard let xlxsFile = XLSXFile(filepath: newPath.path) else {
//        
//    }
}

// MARK: - cammand
let cammand0 = command { (values: [String], parser: ArgumentParser) in
    if parser.hasOption("d") {
        let decryptValues = try aes.decrypt(values)
            .map { $0 ?? "nil" }
            .joined(separator: "\n")

        print(decryptValues)
    } else if parser.hasOption("e") {
        let encryptValues = try aes.encrypt(values)
            .map { $0 ?? "nil" }
            .joined(separator: "\n")

        print(encryptValues)
    } else if parser.hasOption("f"),
       let filePath = values.first,
       let path = Path.instanceOfPath(filePath) as? FilePath,
       path.pathExtension == "strings"
    {
        let encryptContent = try path.readLines()
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty })
            .map({
                let components = $0.components(separatedBy: " = ")
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1].trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\";")))
                let encryptValue = try aes.encrypt(value)
                let encryptLine = String(format: "%@ = \"%@\";", key, encryptValue)
                
                let origin: String = String(format: "// %@", $0)
                return [origin, encryptLine].joined(separator: "\n")
            })
            .joined(separator: "\n\n")
        
        try save(encryptContent, relativePath: path)
    } else if parser.hasOption("sp"),
              !values.isEmpty
    {
        let files = values.map({ Path.instanceOfPath($0) })
            .filter({ $0 != nil && $0!.isDirectory && $0!.pathExtension == "lproj" })
            .map({ $0 as! DirectoryPath })
        var output: FilePath = DirectoryPath.current.appendFileName("Strings.plist") as! FilePath
        if parser.hasOption("output"),
           let filePath = values.last
        {
            output = FilePath(path: filePath)
            try output.createIfNotExists()
        }
        
        var isDocumentOrigin: Bool = false
        if parser.hasOption("ido") {
            isDocumentOrigin = true
        }
        
        try handleStringsFile(files, output: .plist, toPath: output, isDocumentOrigin: isDocumentOrigin, includePrefix: "gy_")
    } else if parser.hasOption("ps"),
            let filePath = values.first,
            let path = Path.instanceOfPath(filePath) as? FilePath
    {
        var output: DirectoryPath = DirectoryPath.current
        let name: String = "Localizable"
        if parser.hasOption("output"),
           let outputPath = values.last,
           let outputDir = Path.instanceOfPath(outputPath) as? DirectoryPath
        {
            output = outputDir
        }
        
        try handlePlistToStrings(path, name: name, output: output, includePrefix: "gy_")
    }
}

cammand0.run()

