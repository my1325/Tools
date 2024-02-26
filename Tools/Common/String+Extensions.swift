//
//  String+Extesions.swift
//  ToolBox
//
//  Created by mayong on 2024/2/26.
//

import Foundation

extension String {
    var snakeCase: String {
        let retValue = components(separatedBy: "_")
            .map({ String($0.first!.uppercased() + $0.dropFirst()) })
            .joined()
        return String(retValue.first!.lowercased() + retValue.dropFirst())
    }
    
    var withoutAtScale: String {
        if hasSuffix("@1x") || hasSuffix("@2x") || hasSuffix("@3x") {
            return String(dropLast(3))
        }
        return self
    }
    
    var withoutSpaceAndNewLine: String {
        replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/r/n", with: "")
    }

    func nsRangeForSubString(_ subString: String) -> NSRange? {
        guard let range = range(of: subString) else {
            return nil
        }
        return self.toNSRange(range)
    }

    func toNSRange(_ range: Range<String.Index>) -> NSRange {
        guard let from = range.lowerBound.samePosition(in: utf16),
              let to = range.upperBound.samePosition(in: utf16)
        else {
            return NSMakeRange(0, 0)
        }
        return NSMakeRange(utf16.distance(from: utf16.startIndex, to: from), utf16.distance(from: from, to: to))
    }

    func toRange(_ range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
              let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
              let from = String.Index(from16, within: self),
              let to = String.Index(to16, within: self)
        else {
            return nil
        }
        return from ..< to
    }
}
