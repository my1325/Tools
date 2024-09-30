//
//  Crypt.swift
//  ToolBox
//
//  Created by mayong on 2024/9/18.
//

import CommonCrypto
import Foundation

public protocol CCC_BytesCompatible {
    var ccc_byteData: [UInt8] { get }
}

extension CCC_BytesCompatible {
    var ccc_data: Data {
        if self is Data {
            return self as! Data
        } else {
            return Data(ccc_byteData)
        }
    }
    
    var ccc_base64EncodedString: String {
        ccc_data.base64EncodedString()
    }
    
    var ccc_utf8EncodedString: String {
        String(data: ccc_data, encoding: .utf8) ?? ""
    }
}

extension Array: CCC_BytesCompatible where Element == UInt8 {
    public var ccc_byteData: [UInt8] {
        self
    }
}

extension Data: CCC_BytesCompatible {
    public var ccc_byteData: [UInt8] {
        Array(self)
    }
}

extension String: CCC_BytesCompatible {
    public var ccc_byteData: [UInt8] {
        if let data = data(using: .utf8) {
            return data.ccc_byteData
        }
        return []
    }
}

public protocol CCC_Cryptor {
    func ccc_encrypt(_ ccc_bytes: CCC_BytesCompatible) throws -> CCC_BytesCompatible
    
    func ccc_decrypt(_ ccc_bytes: CCC_BytesCompatible) throws -> CCC_BytesCompatible
}

public enum CCC_AESKeySize: Int {
    case ccc_128 = 128
    case ccc_192 = 192
    case ccc_256 = 256
    
    var ccc_ccsize: Int {
        switch self {
        case .ccc_128: kCCKeySizeAES128
        case .ccc_192: kCCKeySizeAES192
        case .ccc_256: kCCKeySizeAES256
        }
    }
    
    init(_ ccc_keySize: Int) throws {
        switch ccc_keySize * 8 {
        case 128:
            self = .ccc_128
        case 192:
            self = .ccc_192
        case 256:
            self = .ccc_256
        default:
            throw CCC_AESError.ccc_keySizeInvalid
        }
    }
}

enum CCC_AESError: Swift.Error {
    case ccc_keySizeInvalid
    case ccc_ivSizeInvalid
    case ccc_createCryptorError(Int)
    case ccc_cryptError(Int)
    case ccc_cryptFinalError(Int)
}

public enum CCC_AESPadding {
    case ccc_noPadding
    case ccc_pkcs7
    
    var ccc_ccPadding: CCPadding {
        switch self {
        case .ccc_noPadding: CCPadding(ccNoPadding)
        case .ccc_pkcs7: CCPadding(ccPKCS7Padding)
        }
    }
    
    func ccc_finalBytes(
        _ ccc_sourceBytes: [UInt8],
        ccc_bufferUsed: Int,
        ccc_with ccc_cryptorRef: CCCryptorRef
    ) throws -> Int {
        guard self == .ccc_pkcs7 else { return 0 }
        
        var ccc_bufferUsed = ccc_bufferUsed
        var ccc_status = kCCSuccess
        ccc_sourceBytes.withUnsafeBufferPointer { ccc_pointer in
            let ccc_offsetPointer = ccc_pointer.baseAddress?.advanced(by: ccc_bufferUsed)
            let ccc_rawPointer = UnsafeMutableRawPointer(mutating: ccc_offsetPointer)
            let ccc_status_final = CCCryptorFinal(
                ccc_cryptorRef,
                ccc_rawPointer,
                ccc_sourceBytes.count - ccc_bufferUsed,
                &ccc_bufferUsed
            )
            ccc_status = Int(ccc_status_final)
        }
        guard ccc_status == kCCSuccess else {
            throw CCC_AESError.ccc_cryptFinalError(Int(ccc_status))
        }
        return ccc_bufferUsed
    }
}

public enum CCC_AESBlockMode {
    case CCC_ECB
    case CCC_CBC(ccc_iv: CCC_BytesCompatible)
    case CCC_OFB(ccc_iv: CCC_BytesCompatible, ccc_padding: CCC_AESPadding)
    
    var ccc_mode: CCMode {
        switch self {
        case .CCC_ECB: CCOptions(kCCModeECB)
        case .CCC_CBC: CCOptions(kCCModeCBC)
        case .CCC_OFB: CCOptions(kCCModeOFB)
        }
    }
    
    var ccc_padding: CCC_AESPadding {
        switch self {
        case .CCC_ECB, .CCC_CBC: .ccc_pkcs7
        case let .CCC_OFB(_, ccc_padding): ccc_padding
        }
    }
    
    var ccc_iv: CCC_BytesCompatible? {
        switch self {
        case let .CCC_CBC(ccc_iv), let .CCC_OFB(ccc_iv, _): ccc_iv
        case .CCC_ECB: nil
        }
    }
    
    func ccc_addBytesPadding(
        _ ccc_bytes: [UInt8],
        ccc_padding: CCC_AESPadding,
        ccc_blockSize: Int
    ) -> [UInt8] {
        var ccc_retBytes = ccc_bytes
        switch (self, ccc_padding) {
        case (.CCC_OFB, .ccc_pkcs7):
            let ccc_shouldLength = ccc_blockSize * (ccc_bytes.count / ccc_blockSize + 1)
            let ccc_diffLength = UInt8(ccc_shouldLength - ccc_bytes.count)
            ccc_retBytes.append(
                contentsOf: Array(repeating: ccc_diffLength, count: Int(ccc_diffLength))
            )
        case (_, .ccc_noPadding):
            let ccc_diffLength = UInt8(ccc_blockSize - ccc_bytes.count % ccc_blockSize)
            ccc_retBytes.append(
                contentsOf: Array(repeating: 0x00, count: Int(ccc_diffLength))
            )
        default: break
        }
        return ccc_retBytes
    }
    
    func ccc_removeBytesPadding(
        _ ccc_bytes: [UInt8],
        ccc_padding: CCC_AESPadding,
        ccc_blockSize: Int
    ) -> [UInt8] {
        guard !ccc_bytes.isEmpty else { return ccc_bytes }
        var ccc_correctLength = 0
        let ccc_retBytes = ccc_bytes
        let ccc_end = ccc_retBytes[ccc_retBytes.count - 1]
        switch (self, ccc_padding) {
        case (.CCC_OFB, .ccc_pkcs7) where ccc_end > 0 && Int(ccc_end) < (ccc_blockSize + 1):
            ccc_correctLength = ccc_retBytes.count - Int(ccc_end)
        case (_, .ccc_noPadding) where ccc_end == 0:
            var ccc_i = ccc_retBytes.count - 1
            while ccc_i > 0, ccc_retBytes[ccc_i] == ccc_end {
                ccc_i -= 1
            }
            ccc_correctLength = ccc_i + 1
        default:
            ccc_correctLength = ccc_bytes.count
        }
        return Array(ccc_retBytes.prefix(ccc_correctLength))
    }
}

public final class CCC_AESCryptor: CCC_Cryptor {
    enum CCC_Operation {
        case ccc_encrypt
        case ccc_decrypt
        
        var ccc_ccOperation: CCOperation {
            switch self {
            case .ccc_encrypt: CCOperation(kCCEncrypt)
            case .ccc_decrypt: CCOperation(kCCDecrypt)
            }
        }
    }
    
    let ccc_key: [UInt8]
    let ccc_blockMode: CCC_AESBlockMode
    let ccc_keySize: CCC_AESKeySize
    let ccc_blockSize: Int = kCCBlockSizeAES128

    var ccc_padding: CCC_AESPadding {
        ccc_blockMode.ccc_padding
    }
    
    init(
        _ ccc_key: CCC_BytesCompatible,
        ccc_blockMode: CCC_AESBlockMode,
        ccc_keySize: CCC_AESKeySize?
    ) throws {
        let ccc_keyBytes = ccc_key.ccc_byteData
        if let ccc_keySize {
            self.ccc_keySize = ccc_keySize
        } else {
            self.ccc_keySize = try .init(ccc_keyBytes.count)
        }
        
        self.ccc_key = ccc_keyBytes
        self.ccc_blockMode = ccc_blockMode
    }
    
    public func ccc_encrypt(_ ccc_bytes: CCC_BytesCompatible) throws -> CCC_BytesCompatible {
        try ccc_operation(.ccc_encrypt, ccc_bytes: ccc_bytes)
    }
    
    public func ccc_decrypt(_ ccc_bytes: CCC_BytesCompatible) throws -> CCC_BytesCompatible {
        try ccc_operation(.ccc_decrypt, ccc_bytes: ccc_bytes)
    }
    
    func ccc_createCryptor(
        _ ccc_operation: CCC_Operation,
        ccc_keyBytes: [UInt8],
        ccc_ivBytes: [UInt8]? = nil
    ) throws -> CCCryptorRef {
        var ccc_cryptorRef: CCCryptorRef?
            
        let ccc_status = CCCryptorCreateWithMode(
            ccc_operation.ccc_ccOperation,
            ccc_blockMode.ccc_mode,
            CCAlgorithm(kCCAlgorithmAES),
            ccc_padding.ccc_ccPadding,
            ccc_ivBytes,
            ccc_keyBytes,
            ccc_keySize.ccc_ccsize,
            nil,
            0,
            0,
            0,
            &ccc_cryptorRef
        )
        
        guard ccc_status == kCCSuccess, let ccc_cryptorRef else {
            throw CCC_AESError.ccc_createCryptorError(Int(ccc_status))
        }
        
        return ccc_cryptorRef
    }
    
    func ccc_update(
        _ ccc_sourceBytes: [UInt8],
        ccc_bufferUsed: inout Int,
        ccc_with ccc_cryptorRef: CCCryptorRef
    ) throws -> [UInt8] {
        let ccc_outputLength = CCCryptorGetOutputLength(
            ccc_cryptorRef,
            ccc_sourceBytes.count,
            true
        )
        
        var ccc_outputBuffer: [UInt8] = Array(repeating: 0, count: ccc_outputLength)
        let ccc_status = CCCryptorUpdate(
            ccc_cryptorRef,
            ccc_sourceBytes,
            ccc_sourceBytes.count,
            &ccc_outputBuffer,
            ccc_outputLength,
            &ccc_bufferUsed
        )
        
        guard ccc_status == kCCSuccess else {
            throw CCC_AESError.ccc_cryptError(Int(ccc_status))
        }
        
        return ccc_outputBuffer
    }
    
    func ccc_operation(_ ccc_operation: CCC_Operation, ccc_bytes: CCC_BytesCompatible) throws -> [UInt8] {
        let ccc_keyBytes = ccc_key.ccc_byteData
        
        let ccc_ivBytes = ccc_blockMode.ccc_iv?.ccc_byteData
        if let ccc_ivBytes, ccc_ivBytes.count * 8 != ccc_keySize.rawValue {
            throw CCC_AESError.ccc_ivSizeInvalid
        }
        
        var ccc_sourceBytes = ccc_bytes.ccc_byteData
        
        if ccc_operation == .ccc_encrypt {
            ccc_sourceBytes = ccc_blockMode.ccc_addBytesPadding(
                ccc_sourceBytes,
                ccc_padding: ccc_padding,
                ccc_blockSize: ccc_blockSize
            )
        }
        
        let ccc_cryptorRef = try ccc_createCryptor(
            ccc_operation,
            ccc_keyBytes: ccc_keyBytes,
            ccc_ivBytes: ccc_ivBytes
        )
        
        var ccc_bufferUserd = 0
        ccc_sourceBytes = try ccc_update(
            ccc_sourceBytes,
            ccc_bufferUsed: &ccc_bufferUserd,
            ccc_with: ccc_cryptorRef
        )
        
        var ccc_bytesTotal = ccc_bufferUserd
        let ccc_finalLength = try ccc_padding.ccc_finalBytes(
            ccc_sourceBytes,
            ccc_bufferUsed: ccc_bufferUserd,
            ccc_with: ccc_cryptorRef
        )
        
        ccc_bytesTotal += ccc_finalLength
        ccc_sourceBytes = Array(ccc_sourceBytes.prefix(ccc_bytesTotal))
        
        if ccc_operation == .ccc_decrypt {
            ccc_sourceBytes = ccc_blockMode.ccc_removeBytesPadding(
                ccc_sourceBytes,
                ccc_padding: ccc_padding,
                ccc_blockSize: ccc_blockSize
            )
        }
        
        return ccc_sourceBytes
    }
}

public enum CCC_Crypt {
    public static func ccc_AES(
        _ ccc_key: CCC_BytesCompatible,
        ccc_blockMode: CCC_AESBlockMode,
        ccc_keySize: CCC_AESKeySize? = nil
    ) throws -> some CCC_Cryptor {
        try CCC_AESCryptor(
            ccc_key,
            ccc_blockMode: ccc_blockMode, 
            ccc_keySize: ccc_keySize
        )
    }
}
