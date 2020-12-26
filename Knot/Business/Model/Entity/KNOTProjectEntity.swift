//
//  KNOTTodoItemEntity.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

protocol JSONable: Codable, CustomStringConvertible, CustomDebugStringConvertible {
}

extension JSONable {
    func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
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
    
    static func fromJSONData(_ data: Data) throws -> Self {
        return try JSONDecoder().decode(self, from: data)
    }
}


class KNOTProjectEntity: JSONable, Equatable {
    var id: Int64 { Int64(creationDate.timeIntervalSince1970 * 1000) }
    var creationDate: Date
    var priority: Int64
    var name: String
    var planIds: [String]?
    
    init(creationDate: Date, priority: Int64, name: String) {
        self.creationDate = creationDate
        self.priority = priority
        self.name = name
    }
    
    static func == (lhs: KNOTProjectEntity, rhs: KNOTProjectEntity) -> Bool {
        return lhs.id == rhs.id
    }
}

class KNOTPlanEntity: JSONable, Equatable {
    var id: Int64 { Int64(creationDate.timeIntervalSince1970 * 1000) }
    var creationDate: Date
    var priority: Int64
    var content: String
    var flagColor: UInt32
    var items: [KNOTPlanItemEntity]?
    var remindTimeInterval: TimeInterval?
    var remindTime: Date?
    var projectId: String?
    
    init(creationDate: Date, priority: Int64, content: String, flagColor: UInt32) {
        self.creationDate = creationDate
        self.priority = priority
        self.content = content
        self.flagColor = flagColor
    }
    
    static func == (lhs: KNOTPlanEntity, rhs: KNOTPlanEntity) -> Bool {
        return lhs.id == rhs.id
    }
}

class KNOTPlanItemEntity: Codable {
    var content: String
    var isDone = false
    
    init(content: String, isDone: Bool = false) {
        self.content = content
        self.isDone = isDone
    }
}
