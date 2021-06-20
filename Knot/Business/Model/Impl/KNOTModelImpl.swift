//
//  KNOTModelImpl.swift
//  Knot
//
//  Created by 苏杨 on 2021/3/28.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift
import CloudKit

func KNOTModelDefaultImpl() -> KNOTModel {
    return KNOTModelImpl()
}

private class KNOTModelImpl: KNOTModel {
    private var ckContainer: CKContainer { CKContainer.default() }
    private var database: CKDatabase { ckContainer.privateCloudDatabase }
    
    private var loadTask: Task<Void>?
    
    let plansSubject = Subject<ArraySubscription<KNOTPlanEntity>>()
    let projectsSubject = Subject<ArraySubscription<KNOTProjectEntity>>()
    
    var planModel: KNOTPlanModel { self }
    var projectModel: KNOTProjectModel { self }
    
    private func accessDatabase<T>(_ action: (@escaping (T?, Error?) -> ()) -> ()) -> Task<Void> {
        let tcs = TaskCompletionSource<Void>()
        action { (result, error) in
            if let e = error {
                tcs.set(error: e)
            } else {
                tcs.set(result: ())
            }
        }
        return tcs.task
    }
    
    private func loadData() -> Task<Void> {
        if let loadTask = self.loadTask {
            return loadTask
        }
        
        if plansSubject.value != nil && projectsSubject.value != nil {
            return Task<Void>(())
        }
        
        var getPlanToProject: (() -> ([CKRecord.ID : KNOTProjectEntity]))!
        let planTask = _loadPlans()
        let projectTask = _loadProjects(&getPlanToProject)
        let t = Task.whenAll([planTask, projectTask])
        self.loadTask = t.continueWith(.mainThread) {
            self.loadTask = nil
            
            if let e = $0.error {
                throw e
            }
            self.plansSubject.publish((planTask.result as? [KNOTPlanEntity], .reset, nil))
            
            let planToProject = getPlanToProject()
            planTask.result?.forEach { plan in
                planToProject[plan.ckRecordID]?.plans?.append(plan as! KNOTPlanEntity)
            }
            
            self.projectsSubject.publish((projectTask.result as? [KNOTProjectEntity], .reset, nil))
        }
        
        return self.loadTask!
    }
    
    private func _loadPlans() -> Task<[KNOTEntityBase]> {
        let queryTcs = TaskCompletionSource<[KNOTEntityBase]>()
        let query = CKQuery(recordType: KNOTPlanEntity.recordType, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { (results, error) in
            guard error == nil else {
                queryTcs.set(error: error!)
                return
            }
            
            guard let records = results, records.isEmpty == false else {
                queryTcs.set(result: [])
                return
            }
            
            var plans = [KNOTPlanEntity]()
            var batchFetchIDs = [CKRecord.ID]()
            var itemToPlan = [CKRecord.ID : KNOTPlanEntity]()
            for record in records {
                var itemRecordIDs: [CKRecord.ID]?
                let plan = KNOTPlanEntity(from: record, itemRecordIDs: &itemRecordIDs)
                plans.append(plan)
                
                if let ids = itemRecordIDs {
                    plan.items = []
                    batchFetchIDs.append(contentsOf: ids)
                    ids.forEach { itemToPlan[$0] = plan }
                }
            }
            
            guard batchFetchIDs.isEmpty == false else {
                queryTcs.set(result: plans)
                return
            }
            
            let batchFetchTcs = TaskCompletionSource<Void>()
            let batchFetch = CKFetchRecordsOperation(recordIDs: batchFetchIDs)
            batchFetch.database = self.database
            batchFetch.perRecordCompletionBlock = { (record, recordID, error) in
                if let e = error {
                    debugPrint(e)
                    return
                }
                
                guard let id = recordID else {
                    debugPrint("null recordID")
                    return
                }
                
                itemToPlan[id]?.items?.append(KNOTPlanItemEntity(from: record!))
            }
            batchFetch.fetchRecordsCompletionBlock = { (records, error) in
                if let e = error {
                    batchFetchTcs.set(error: e)
                } else {
                    batchFetchTcs.set(result: ())
                }
            }
            batchFetch.start()
            
            batchFetchTcs.task.continueWith {
                if let error = $0.error {
                    queryTcs.set(error: error)
                } else {
                    queryTcs.set(result: plans)
                }
            }
        }
        
        return queryTcs.task
    }
    
    func _loadProjects(_ getPlanToProject: inout (() -> ([CKRecord.ID : KNOTProjectEntity]))?) -> Task<[KNOTEntityBase]> {
        var planToProject = [CKRecord.ID : KNOTProjectEntity]()
        let loadProjectsTcs = TaskCompletionSource<[KNOTEntityBase]>()
        let query = CKQuery(recordType: KNOTProjectEntity.recordType, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { (results, error) in
            guard error == nil else {
                loadProjectsTcs.set(error: error!)
                return
            }
            
            guard let records = results, records.isEmpty == false else {
                loadProjectsTcs.set(result: [])
                return
            }
            
            let projs = records.map { (record) -> (KNOTProjectEntity) in
                var planRecordIDs: [CKRecord.ID]?
                let project = KNOTProjectEntity(from: record, planRecordIDs: &planRecordIDs)
                
                if let ids = planRecordIDs {
                    project.plans = []
                    ids.forEach { planToProject[$0] = project }
                }
                
                return project
            }
            
            loadProjectsTcs.set(result: projs)
        }
        
        getPlanToProject = { planToProject }
        
        return loadProjectsTcs.task
    }
}

extension KNOTModelImpl: KNOTPlanModel {
    func loadPlans() -> Task<Void> {
        return loadData()
    }
    
    func plans(onDay day: Date) -> [KNOTPlanEntity] {
        guard let plans = plansSubject.value?.0 else {
            return []
        }
        
        let calendar = Calendar.current
        let targetDateComponents = calendar.dateComponents([ .year, .month, .day ], from: day)
        let items = plans.filter {
            let planDateComponents = calendar.dateComponents([ .year, .month, .day ], from: $0.remindDate)
            guard let repeatInfo = $0.repeat else {
                return planDateComponents == targetDateComponents
            }
            
            let planDate = calendar.date(from: planDateComponents)!
            let targetDate = calendar.date(from: targetDateComponents)!
            
            guard planDate <= targetDate else {
                return false
            }
            
            let interval = targetDate.timeIntervalSince(planDate)
            
            switch repeatInfo.type {
            case .Day:
                return Int64(interval) % Int64(repeatInfo.interval * 24 * 3600) == 0
            case .Week:
                return Int64(interval) % Int64(repeatInfo.interval * 7 * 24 * 3600) == 0
            case .Month:
                return targetDateComponents.day == planDateComponents.day
                    && (targetDateComponents.month! - planDateComponents.month!) % repeatInfo.interval == 0
            case .Year:
                return targetDateComponents.day == planDateComponents.day
                    && targetDateComponents.month == planDateComponents.month
                    && (targetDateComponents.year! - planDateComponents.year!) % repeatInfo.interval == 0
            }
        }
        
        return items
    }
    
    func updatePlan(_ plan: KNOTPlanEntity) -> Task<Void> {
        var plans = plansSubject.value?.0 ?? []
        if let index = plans.firstIndex(of: plan) {
            plansSubject.publish((plans, .update, [index]))
        } else {
            plans.append(plan)
            plansSubject.publish((plans, .insert, [plans.endIndex - 1]))
        }
        
        let tcs = TaskCompletionSource<Void>()
        let records = [ plan.ckRecord ] + (plan.items?.map({ $0.ckRecord }) ?? [])
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        modifyOperation.database = database
        modifyOperation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let e = error {
                tcs.set(error: e)
            } else {
                plan.ckRecord = records!.first(where: { $0.recordID == plan.ckRecordID })!
                plan.items?.forEach({ (item) in item.ckRecord = records!.first(where: { $0.recordID == item.ckRecordID })! })
                tcs.set(result: ())
            }
        }
        modifyOperation.start()
        
        return tcs.task
    }
    
    func deletePlan(_ plan: KNOTPlanEntity) -> Task<Void> {
        if var plans = plansSubject.value?.0 {
            let index = plans.firstIndex(of: plan)
            plans.removeAll { $0 == plan }
            plansSubject.publish((plans, .remove, index.map { [$0] }))
        }
        
        return accessDatabase { database.delete(withRecordID: plan.ckRecordID, completionHandler: $0) }
    }
    
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel {
        return plan
    }
    
    func planMoreModel(with plan: KNOTPlanEntity) -> KNOTPlanMoreModel {
        return plan
    }
}

extension KNOTPlanEntity: KNOTPlanDetailModel, KNOTPlanMoreModel {
    var plan: KNOTPlanEntity {
        return self
    }
}

extension KNOTModelImpl: KNOTProjectModel {
    func loadProjects() -> Task<Void> {
        return loadData()
    }
    
    func add(plan: KNOTPlanEntity, toProject project: KNOTProjectEntity) -> Task<Void> {
        let projs = projectsSubject.value?.0 ?? []
        let index = projs.firstIndex(of: project)!
        project.plans?.append(plan)
        projectsSubject.publish((projs, .update, [index]))
        
        return accessDatabase { database.save(plan.ckRecord, completionHandler: $0) }
    }
    
    func updateProject(_ proj: KNOTProjectEntity) -> Task<Void> {
        var projs = projectsSubject.value?.0 ?? []
        if let index = projs.firstIndex(of: proj) {
            projectsSubject.publish((projs, .update, [index]))
        } else {
            projs.append(proj)
            projectsSubject.publish((projs, .insert, [projs.endIndex - 1]))
        }
        
        return accessDatabase {  database.save(proj.ckRecord, completionHandler: $0) }
    }
    
    func deleteProject(_ proj: KNOTProjectEntity) -> Task<Void> {
        if var projs = projectsSubject.value?.0 {
            let index = projs.firstIndex(of: proj)
            projs.removeAll { $0 == proj }
            projectsSubject.publish((projs, .remove, index.map { [$0] }))
        }
        
        return accessDatabase { database.delete(withRecordID: proj.ckRecordID, completionHandler: $0) }
    }
    
    func detailModel(with proj: KNOTProjectEntity) -> KNOTProjectDetailModel {
        return proj
    }
}

extension KNOTProjectEntity: KNOTProjectDetailModel {
    var project: KNOTProjectEntity {
        return self
    }
}
