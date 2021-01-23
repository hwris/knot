//
//  KNOTEntityBase.swift
//  Knot
//
//  Created by 苏杨 on 2021/1/23.
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

class KNOTEntityBase {
    let id: String
    
    init() {
        id = UUID().uuidString
    }
}
