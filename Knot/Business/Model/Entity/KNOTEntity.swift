//
//  KNOTTodoItemEntity.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import CloudKit

class KNOTEntityBase: Equatable {
    typealias ID = String
    
    let id: ID
    private var _ckRecord: CKRecord?
    
    init(id: ID = UUID().uuidString) {
        self.id = id
    }
    
    init(from record: CKRecord) {
        id = record.recordID.recordName
        _ckRecord = record
    }
    
    var ckRecordID: CKRecord.ID {
        return _ckRecord?.recordID ?? CKRecord.ID(recordName: id)
    }
    
    var ckRecord: CKRecord {
        get {
            return _ckRecord ?? CKRecord(recordType: type(of:self).recordType, recordID: ckRecordID)
        }
        set {
            _ckRecord = newValue
        }
    }
    
    class var recordType: CKRecord.RecordType {
        fatalError("Subclass implements")
    }
    
    static func == (lhs: KNOTEntityBase, rhs: KNOTEntityBase) -> Bool {
        return lhs.id == rhs.id
    }
}

class KNOTProjectEntity: KNOTEntityBase {
    var priority: Double
    var name: String
    var flagColor: UInt32
    var plans: [KNOTPlanEntity]?
    
    init(priority: Double, name: String, flagColor: UInt32) {
        self.priority = priority
        self.name = name
        self.flagColor = flagColor
        super.init()
    }
    
    init(from record: CKRecord, planRecordIDs: inout [CKRecord.ID]?) {
        priority = record["priority"] as! Double
        name = record["name"] as! String
        flagColor = record["flagColor"] as! UInt32
        planRecordIDs = (record["plans"] as? [CKRecord.Reference])?.map({ $0.recordID })
        super.init(from: record)
    }
    
    override var ckRecord: CKRecord {
        get {
            let record = super.ckRecord
            record["priority"] = priority
            record["name"] = name
            record["flagColor"] = flagColor
            record["plans"] = plans?.map({ CKRecord.Reference(recordID: $0.ckRecordID, action: .none) })
            return record
        }
        
        set {
            super.ckRecord = newValue
        }
    }
    
    override class var recordType: CKRecord.RecordType {
        return "Project"
    }
}

class KNOTPlanEntity: KNOTEntityBase {   
    struct Repeat {
        enum Type_: Int, CaseIterable { case Day, Week, Month, Year}
        var interval: Int
        var type: Type_
    }
    
    var remindDate: Date
    var priority: Double
    var content: String
    var flagColor: UInt32
    var items: [KNOTPlanItemEntity]?
    var isDone = false
    var remindTime: Date?
    var `repeat`: Repeat?
    
    init(remindDate: Date, priority: Double, content: String, flagColor: UInt32) {
        self.remindDate = remindDate
        self.priority = priority
        self.content = content
        self.flagColor = flagColor
        super.init()
    }
    
    init(from record: CKRecord, itemRecordIDs: inout [CKRecord.ID]?) {
        remindDate = record["remindDate"] as! Date
        priority = record["priority"] as! Double
        content = record["content"] as! String
        flagColor = record["flagColor"] as! UInt32
        isDone = record["isDone"] as! Bool
        remindTime = record["remindTime"] as? Date
        itemRecordIDs = (record["items"] as? [CKRecord.Reference])?.map({ $0.recordID })
        
        if let repeatInterval = record["repeatInterval"] as? Int,
           let repeatTypeRawValue = record["repeatType"] as? Int,
           let repeatType = Repeat.Type_(rawValue: repeatTypeRawValue) {
            `repeat` = Repeat(interval: repeatInterval, type: repeatType)
        }
        
        super.init(from: record)
    }
    
    override var ckRecord: CKRecord {
        get {
            let record = super.ckRecord
            record["remindDate"] = remindDate
            record["priority"] = priority
            record["content"] = content
            record["flagColor"] = flagColor
            record["isDone"] = isDone
            record["remindTime"] = remindTime
            record["repeatInterval"] = `repeat`?.interval
            record["repeatType"] = `repeat`?.type.rawValue
            record["items"] = items?.map({ CKRecord.Reference(recordID: $0.ckRecordID, action: .none) })
            
            return record
        }
        
        set {
            super.ckRecord = newValue
        }
    }
    
    override class var recordType: CKRecord.RecordType {
        return "Plan"
    }
}

class KNOTPlanItemEntity: KNOTEntityBase {
    var content: String
    var isDone = false
    
    init(content: String, isDone: Bool = false) {
        self.content = content
        self.isDone = isDone
        super.init()
    }
    
    override init(from record: CKRecord) {
        content = record["content"] as! String
        isDone = record["isDone"] as! Bool
        super.init(from: record)
    }
    
    override var ckRecord: CKRecord {
        get {
            let record = super.ckRecord
            record["content"] = content
            record["isDone"] = isDone
            return record
        }
        
        set {
            super.ckRecord = newValue
        }
    }
    
    override class var recordType: CKRecord.RecordType {
        return "PlanItem"
    }
}
