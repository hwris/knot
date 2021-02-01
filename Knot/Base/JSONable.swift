//
//  JSONable.swift
//  Knot
//
//  Created by 苏杨 on 2021/1/31.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import Foundation

protocol JSONable: Codable, CustomStringConvertible, CustomDebugStringConvertible, Equatable {
}

extension JSONable {
    func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    static func fromJSONData(_ data: Data) throws -> Self {
        return try JSONDecoder().decode(self, from: data)
    }
    
    var description: String {
        if let data = try? toJsonData(),
            let desc = String(data: data, encoding: .utf8)  {
            return desc
        }
        
        return "\(self)"
    }
    
    var debugDescription: String {
        return description
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard let lJson = try? lhs.toJsonData(), let rJson = try? rhs.toJsonData() else {
            return false
        }
        
        return lJson == rJson
    }
}

protocol JSONDefaultValue {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

@propertyWrapper
struct JSONDefault<T: JSONDefaultValue> {
    var wrappedValue: T.Value
}

extension JSONDefault: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_ type: JSONDefault<T>.Type, forKey key: Key) throws -> JSONDefault<T> where T: JSONDefaultValue {
        try decodeIfPresent(type, forKey: key) ?? JSONDefault(wrappedValue: T.defaultValue)
    }
}

extension Bool {
    enum False: JSONDefaultValue {
        static let defaultValue = false
    }
    enum True: JSONDefaultValue {
        static let defaultValue = true
    }
}

extension JSONDefault {
    typealias True = JSONDefault<Bool.True>
    typealias False = JSONDefault<Bool.False>
}
