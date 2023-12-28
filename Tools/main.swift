//
//  main.swift
//  Tools
//
//  Created by mayong on 2023/2/2.
//

import AppKit
import AVFoundation
import Commander
import CoreImage
import CryptoSwift
import FilePath
import QuartzCore
import ZipArchive

let arguments = CommandLine.arguments

let key = "asjdlfjasdlkfaqw"
let iv = "alsjflkasdjflkaq"

let aes = try AESCoder(key: key, iv: iv)

let newKey = "qwertyasdf123456"
let newIV = "mnbvcxzlkjhyuiop"

let newAes = try AESCoder(key: newKey, iv: newIV)

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
            retCache[pathName] = cache
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
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter(lineFilter)
        .forEach {
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
        }
    return retValue
}

// MARK: - Plist To Strings

func handlePlistToStrings(_ plist: FilePath, name: String, output: DirectoryPath, includePrefix: String, replacePrefix: String) throws {
    let retCache: [String: String] = try handlePlist(plist, includePrefix: includePrefix, replacePrefix: replacePrefix)
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

func handlePlist(_ plist: FilePath, includePrefix: String, replacePrefix: String) throws -> [String: String] {
    var retValue: [String: [String]] = [:]
    let data = try plist.readData()
    let decoder = PropertyListDecoder()
    let cached = try decoder.decode([String: [String: String]].self, from: data)
    for (language, languageCached) in cached {
        for (key, value) in languageCached {
            var strings: [String] = Array(repeating: "", count: 2)
            strings[0] = String(format: "// \"%@\" = \"%@\";", key, value)
            if key.hasPrefix(includePrefix) {
                let replaceRange = key.startIndex ..< key.index(key.startIndex, offsetBy: includePrefix.count)
                var newKey = key
                newKey.removeSubrange(replaceRange)
                newKey = String(format: "%@%@", replacePrefix, newKey)
                strings[1] = String(format: "\"%@\" = \"%@\";", newKey, try newAes.encrypt(value))
            } else {
                strings[1] = String(format: "\"%@\" = \"%@\";", key, value)
            }
            let keyString = strings.joined(separator: "\n")
            var languageStrings = retValue[language] ?? []
            languageStrings.append(keyString)
            retValue[language] = languageStrings
        }
    }
    
    return retValue.mapValues { $0.joined(separator: "\n\n") }
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
            retCache[pathName] = cache
        }
    }
    
//    guard let xlxsFile = XLSXFile(filepath: newPath.path) else {
//        print("create xlxs file failed")
//        return
//    }
}

func movePngImageToDst(_ originDir: DirectoryPath, dstDir: DirectoryPath) throws {
    for path in originDir.directoryIterator() {
        if let dirPath = path as? DirectoryPath {
            try movePngImageToDst(dirPath, dstDir: dstDir)
        } else if let filePath = path as? FilePath, filePath.pathExtension == "png" {
            let newPath = dstDir.appendFileName(filePath.lastPathConponent)
            try filePath.moveToNewPath(newPath)
        }
    }
}

func alignAssetsToDst(_ originDir: DirectoryPath, dstDir: DirectoryPath?) throws {
    var _originDir = originDir
    if let dstDir {
        try _originDir.copyToPath(dstDir)
        _originDir = dstDir
    }
    
    try alignAssets(_originDir)
}

func alignAssets(_ originDir: DirectoryPath) throws {
    for subpath in originDir.directoryIterator() {
        if subpath.pathExtension == "imageset", let subdir = subpath as? DirectoryPath {
            var alignName = subpath.lastPathConponent
            if let dotRange = alignName.range(of: ".") {
                let nameRange = alignName.startIndex ..< dotRange.lowerBound
                alignName = String(alignName[nameRange])
            }
            
            for filePath in subdir.directoryIterator() {
                guard filePath.pathExtension == "png" else { continue }
                var newName = filePath.lastPathConponent
                var name = filePath.lastPathConponent
                if let atRange = name.range(of: "@") {
                    let nameRange = name.startIndex ..< atRange.lowerBound
                    name = String(name[nameRange])
                    newName = newName.replacingOccurrences(of: name, with: alignName)
                } else if let dotRange = name.range(of: "."), dotRange.lowerBound != name.startIndex {
                    let nameRange = name.startIndex ..< dotRange.lowerBound
                    name = String(name[nameRange])
                    newName = newName.replacingOccurrences(of: name, with: alignName)
                }
                _ = try filePath.rename(newName)
            }
        } else if let subdir = subpath as? DirectoryPath {
            try alignAssets(subdir)
        }
    }
}

private func pixelBufferWithCGImage(_ cgImage: CGImage) -> CVPixelBuffer? {
    let properties: [String: Any] = [:]
    let options: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        kCVPixelBufferIOSurfacePropertiesKey: properties
    ]
    
    var pixelBuffer: CVPixelBuffer?
    let width = cgImage.width
    let height = cgImage.height
    let retStatus = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)
    guard retStatus == kCVReturnSuccess, let pixelBuffer else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0)) }
    
    let ciContext = CIContext()
    ciContext.render(CIImage(cgImage: cgImage), to: pixelBuffer)
    return pixelBuffer
}

func makeVideo(_ image: CGImage, outputURL: URL, size: CGSize, frameCount: Int = 5, framePerseconds: Int = 24, block: @escaping () -> Void) throws {
    let videoWrite = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let videoSettings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: Int(size.width),
        AVVideoHeightKey: Int(size.height)
    ]
    
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    
    let sourcePixelBufferAttributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB
    ]
    
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
    
    videoWrite.add(writerInput)
    
    videoWrite.startWriting()
    videoWrite.startSession(atSourceTime: .zero)
    var frame = 0
    writerInput.requestMediaDataWhenReady(on: DispatchQueue.global()) {
        while writerInput.isReadyForMoreMediaData {
            frame += 1
            if frame >= frameCount * framePerseconds {
                writerInput.markAsFinished()
                videoWrite.finishWriting(completionHandler: block)
                break
            }
           
            if let pixelBuffer = pixelBufferWithCGImage(image),
               !adaptor.append(pixelBuffer, withPresentationTime: CMTimeMake(value: Int64(frame), timescale: Int32(framePerseconds)))
            {
                print("append pixel buffer failed")
                print(videoWrite.error)
            }
        }
    }
}

func drawImage(_ color: NSColor, size: CGSize) -> CGImage? {
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0)
    else {
        assertionFailure("[Kingfisher] Image representation cannot be created.")
        return nil
    }
    rep.size = size
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        assertionFailure("[Kingfisher] Image context cannot be created.")
        return nil
    }
    
    NSGraphicsContext.current = context
    let cgContext = context.cgContext
    cgContext.setFillColor(color.cgColor)
    cgContext.fill([CGRect(origin: .zero, size: size)])
    if let image = cgContext.makeImage() {
        let nsImage = NSImage(cgImage: image, size: size)
        if let imageData = nsImage.tiffRepresentation,
           let imageRep = NSBitmapImageRep(data: imageData),
           let dataToWrite = imageRep.representation(using: .png, properties: [:])
        {
            do {
                try dataToWrite.write(to: URL(filePath: DirectoryPath.desktop.appendFileName("black.png").path))
            } catch {
                print("save image failed \(error)")
            }
        }
        return image
    }
    return nil
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
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map {
                let components = $0.components(separatedBy: " = ")
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1].trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\";")))
                let encryptValue = try aes.encrypt(value)
                let encryptLine = String(format: "%@ = \"%@\";", key, encryptValue)
                
                let origin: String = .init(format: "// %@", $0)
                return [origin, encryptLine].joined(separator: "\n")
            }
            .joined(separator: "\n\n")
        
        try save(encryptContent, relativePath: path)
    } else if parser.hasOption("rcf"),
              let filePath = values.first,
              let path = Path.instanceOfPath(filePath) as? FilePath,
              path.pathExtension == "strings"
    {
        let encryptContent = try path.readLines()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasPrefix("//") }
            .map {
                var retString = $0
                if let firstRange = $0.firstRange(of: "//") {
                    retString.removeSubrange(firstRange)
                }
                return retString
            }
            .joined(separator: "\n\n")
        
        try save(encryptContent, toNewPath: path, relativePath: path)
    } else if parser.hasOption("sp"),
              !values.isEmpty
    {
        let files = values.map { Path.instanceOfPath($0) }
            .filter { $0 != nil && $0!.isDirectory && $0!.pathExtension == "lproj" }
            .map { $0 as! DirectoryPath }
        var output: FilePath = DirectoryPath.current.appendFileName("Strings.plist") as! FilePath
        if parser.hasOption("output"),
           let filePath = values.last
        {
            output = FilePath(path: filePath)
            try output.createIfNotExists()
        }
        
        var isDocumentOrigin = false
        if parser.hasOption("ido") {
            isDocumentOrigin = true
        }
        
        try handleStringsFile(files, output: .plist, toPath: output, isDocumentOrigin: isDocumentOrigin, includePrefix: "gy_")
    } else if parser.hasOption("ps"),
              let filePath = values.first,
              let path = Path.instanceOfPath(filePath) as? FilePath
    {
        var output = DirectoryPath.current
        let name = "Localizable"
        if parser.hasOption("output"),
           let outputPath = values.last,
           let outputDir = Path.instanceOfPath(outputPath) as? DirectoryPath
        {
            output = outputDir
        }
        
        try handlePlistToStrings(path, name: name, output: output, includePrefix: "gy_", replacePrefix: "dcr_")
    } else if parser.hasOption("sx") {
        let files = values.map { Path.instanceOfPath($0) }
            .filter { $0 != nil && $0!.isDirectory && $0!.pathExtension == "lproj" }
            .map { $0 as! DirectoryPath }
        var output: FilePath = DirectoryPath.current.appendFileName("Strings.plist") as! FilePath
        if parser.hasOption("output"),
           let filePath = values.last
        {
            output = FilePath(path: filePath)
            try output.createIfNotExists()
        }
        
        var isDocumentOrigin = false
        if parser.hasOption("ido") {
            isDocumentOrigin = true
        }
        
        try handleStringsFile(files, output: .xlsx, toPath: output, isDocumentOrigin: isDocumentOrigin, includePrefix: "gy_")
    } else if parser.hasOption("zip") {
        let dir = values[0]
        let passwrod = values[1]
        let path = Path.instanceOfPath(dir) as! DirectoryPath
        let newPath = path.parent.appendFileName(path.lastPathConponent, ext: "zip")
        if SSZipArchive.createZipFile(atPath: newPath.path, withContentsOfDirectory: dir, withPassword: passwrod) {
            print("create success")
        }
    } else if parser.hasOption("rp"), let path = values.first {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let dict = try PropertyListDecoder().decode([String: String].self, from: data)
        let decryptDict = try dict.mapValues { try aes.decrypt($0) }
        let newEncrypt = try decryptDict.map {
            var key = $0.key
            if !key.hasPrefix("dcr_") {
                key = String(format: "dcr_%@", key)
            }
            let value = try newAes.encrypt($0.value!)
            return (key, value)
        }
        
        var newEncryptDict: [String: String] = [:]
        newEncrypt.forEach { newEncryptDict[$0.0] = $0.1 }
        let oldPath = FilePath(path: path)
        try oldPath.remove()
        let newData = try PropertyListEncoder().encode(newEncryptDict)
        try oldPath.writeData(newData)
    } else if parser.hasOption("mp"), let directory = values.first, let dst = values.last {
        let path = DirectoryPath(path: directory)
        let dstDir = DirectoryPath(path: dst)
        try movePngImageToDst(path, dstDir: dstDir)
    } else if parser.hasOption("alignAssets"), let directory = values.first {
        var output = ""
        if values.count > 1, let outputDir = values.last {
            output = outputDir
        }
        
        var outputDir: DirectoryPath?
        if !output.isEmpty {
            outputDir = .init(path: output)
        }
        
        try alignAssetsToDst(DirectoryPath(path: directory), dstDir: outputDir)
    } else if parser.hasOption("mv") {
        let mvPath = DirectoryPath.desktop.appendFileName("mvtest1", ext: "mp4")
        let size = CGSize(width: 1080, height: 844)
        if let cgImage = drawImage(.black, size: size) {
            do {
                let wait = DispatchSemaphore(value: 0)
                try makeVideo(cgImage, outputURL: URL(filePath: mvPath.path), size: size, block: {
                    wait.signal()
                })
                wait.wait()
                print("finished")
            } catch {
                print("make video error \(error)")
            }
        }
    }
}

cammand0.run()

// print(try aes.decrypt("lKaTLKDZUsiRz5cMO8+bdJPzK6udGbh8gpHpeegUarPkh5UFi3M4bwR4Qi6cI2tw7NO+mtBMy6ILct6GvtldXg==")!)
// print(try aes.decrypt("uPBSQaVlwQTPS3108xOoAgTumr4v9fKxUm8o5H8BEIA=")!)
// print(try aes.decrypt("uPBSQaVlwQTPS3108xOoAldrBsMqMRJxuCLEOiqdxlo=")!)
// print(try aes.decrypt("yaLs1TtH1crnyjppPWk7XQ==")!)
// print(try aes.decrypt("KUaY6XbsaVePebcZXNkY9w==")!)
// print(try newAes.encrypt("https://s3.amazonaws.com/ns.livegirl.me/wdevent/cs/cs.html"))
// print(try newAes.encrypt("kAgoraMessage_HostFuzzy"))
// print(try newAes.encrypt("kAgoraMessage_HostFuzzy_No"))
// print(try newAes.encrypt("1"))
// print(try newAes.encrypt("00"))
// let cryptCammand = command { (values: [String], parser: ArgumentParser) in
//    if parser.hasOption("d") {
//        try print(values.map({ try newAes.decrypt($0)! }).joined(separator: "\n"))
//    } else if parser.hasOption("e") {
//        try print(values.map({ try newAes.encrypt($0) }).joined(separator: "\n"))
//    }
// }
//
// cryptCammand.run()
