//
//  String+Base64.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-10.
//

import Foundation

extension String {
    /// Safely decodes a Base64 encoded string. Returns the original string if decoding fails.
    var base64Decoded: String {
        guard let data = Data(base64Encoded: self),
              let decodedString = String(data: data, encoding: .utf8) else {
            return self
        }
        return decodedString
    }
}
