//
//  KNOTTodoItemEntity.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

class KNOTProjectEntity: KNOTEntityBase, JSONable {
    let creationDate: Date
    var priority: Int64
    var name: String
    var planIds: [String]?
    
    init(creationDate: Date, priority: Int64, name: String) {
        self.creationDate = creationDate
        self.priority = priority
        self.name = name
        super.init()
    }
}

class KNOTPlanEntity: KNOTEntityBase, JSONable {
    let creationDate: Date
    var priority: Int64
    var content: String
    var flagColor: UInt32
    var items: [KNOTPlanItemEntity]?
    var remindTimeInterval: TimeInterval?
    var remindTime: Date?
    var projectId: String?
    var isDone = false
    
    init(creationDate: Date, priority: Int64, content: String, flagColor: UInt32) {
        self.creationDate = creationDate
        self.priority = priority
        self.content = content
        self.flagColor = flagColor
        super.init()
    }
}

class KNOTPlanItemEntity: KNOTEntityBase, JSONable {
    var content: String
    var isDone = false
    
    init(content: String, isDone: Bool = false) {
        self.content = content
        self.isDone = isDone
        super.init()
    }
}
