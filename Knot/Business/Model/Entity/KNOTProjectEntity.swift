//
//  KNOTTodoItemEntity.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

class KNOTProjectEntity: Codable {
    let id: Int64
    var name: String
    var planIds: [String]?
    
    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }
}

class KNOTPlanEntity: Codable {
    let id: Int64
    var content: String
    var flagColor: UInt32
    var items: [KNOTPlanItemEntity]?
    var remindTimeInterval: TimeInterval?
    var remindTime: Date?
    var projectId: String?
    
    init(id: Int64, content: String, flagColor: UInt32) {
        self.id = id
        self.content = content
        self.flagColor = flagColor
    }
}

class KNOTPlanItemEntity: Codable {
    var content: String
    var isDone = false
}
