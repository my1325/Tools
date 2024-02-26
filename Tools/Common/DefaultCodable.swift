//
//  DefaultCodable.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation

protocol DefaultValueCompatible {
    static var defaultValue: Self { get }
}

extension String: DefaultValueCompatible {
    static var defaultValue: String { "" }
}

extension Bool: DefaultValueCompatible {
    static var defaultValue: Bool { false }
}

@propertyWrapper
struct DefaultDecodable<V: Codable & DefaultValueCompatible>: Codable {
    var wrappedValue: V
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(V.self)) ?? V.defaultValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
