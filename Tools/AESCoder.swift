//
//  AESCoder.swift
//  Tools
//
//  Created by mayong on 2023/10/17.
//

import Foundation
import CryptoSwift

public final class AESCoder {
    public let coder: AES
    public init(coder: AES) {
        self.coder = coder
    }
    
    public convenience init(key: [UInt8], blockMode: BlockMode, padding: Padding = .pkcs7) throws {
        let coder = try AES(key: key, blockMode: blockMode, padding: padding)
        self.init(coder: coder)
    }
    
    public convenience init(key: [UInt8], iv: [UInt8], padding: Padding = .pkcs7) throws {
        try self.init(key: key, blockMode: CBC(iv: iv), padding: padding)
    }
    
    public convenience init(key: [UInt8], padding: Padding = .pkcs7) throws {
        try self.init(key: key, blockMode: ECB(), padding: padding)
    }
    
    public convenience init(key: String, blockMode: BlockMode, padding: Padding = .pkcs7) throws {
        try self.init(key: key.bytes, blockMode: blockMode, padding: padding)
    }
    
    public convenience init(key: String, iv: String, padding: Padding = .pkcs7) throws {
        try self.init(key: key, blockMode: CBC(iv: iv.bytes), padding: padding)
    }
    
    public convenience init(key: String, padding: Padding = .pkcs7) throws {
        try self.init(key: key, blockMode: ECB(), padding: padding)
    }
}

extension AESCoder {
    public func decrypt(_ bytes: [UInt8]) throws -> [UInt8] {
        try coder.decrypt(bytes)
    }
    
    public func decrypt(_ data: Data) throws -> Data {
        Data(try decrypt(data.bytes))
    }
    
    public func decrypt(_ string: String) throws -> String? {
        guard let data = Data(base64Encoded: string) else {
            fatalError("can not convert \(string) to valid data")
        }
        return String(data: try decrypt(data), encoding: .utf8)
    }
    
    public func encrypt(_ bytes: [UInt8]) throws -> [UInt8] {
        try coder.encrypt(bytes)
    }
    
    public func encrypt(_ data: Data) throws -> Data {
        Data(try encrypt(data.bytes))
    }
    
    public func encrypt(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            fatalError("can not convert \(string) to valid data")
        }
        return try encrypt(data).base64EncodedString()
    }
}

extension AESCoder {
    public func decrypt(_ strings: [String]) throws -> [String?] {
        try strings.map(decrypt)
    }
    
    public func encrypt(_ strings: [String]) throws -> [String?] {
        try strings.map(encrypt)
    }
}
