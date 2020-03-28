//
//  KNOTTodoItemEntity.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

class KNOTProjectEntity: Codable {
    
    static var supportsSecureCoding = false
    
    var createDate: Date
    var name: String
    var labelColor: UInt32
    var itemList: [String]?
    var remindTimeInterval: TimeInterval?
    
    init(createDate: Date, name: String, labelColor: UInt32) {
        self.createDate = createDate
        self.name = name
        self.labelColor = labelColor
    }
}
