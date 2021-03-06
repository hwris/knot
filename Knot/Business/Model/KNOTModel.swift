//
//  KNOTModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift
import CloudKit

protocol KNOTModel {
    var planModel: KNOTPlanModel { get }
}

class KNOTModelImpl: KNOTModel {
    private var ckContainer: CKContainer { CKContainer.default() }
    private var database: CKDatabase { ckContainer.privateCloudDatabase }
    
    let plansSubject = Subject<ArraySubscription<KNOTPlanEntity>>()
    let projectsSubject = Subject<ArraySubscription<KNOTProjectEntity>>()
    
    var planModel: KNOTPlanModel { self }
    
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
}

extension KNOTModelImpl: KNOTPlanModel {
    func loadPlans() -> Task<Void> {
        var plans = [KNOTPlanEntity]()
        var tasks = [Task<Void>]()
        let query = CKQuery(recordType: KNOTPlanEntity.recordType, predicate: NSPredicate(value: true))
        let queryTcs = TaskCompletionSource<Void>()
        tasks.append(queryTcs.task)
        database.perform(query, inZoneWith: nil) { (results, error) in
            guard error == nil else {
                queryTcs.set(error: error!)
                return
            }
            
            guard let records = results else {
                queryTcs.set(result: ())
                return
            }
            
            for record in records {
                var itemRecordIDs: [CKRecord.ID]?
                var projectRecordID: CKRecord.ID?
                let plan = KNOTPlanEntity(from: record, itemRecordIDs: &itemRecordIDs, projectRecordID: &projectRecordID)
                
                plans.append(plan)
                
                var queryRecordIDs = [CKRecord.ID]()
                if itemRecordIDs != nil {
                    plan.items = []
                    queryRecordIDs.append(contentsOf: itemRecordIDs!)
                }
                if projectRecordID != nil {
                    queryRecordIDs.append(projectRecordID!)
                }
                
                if queryRecordIDs.isEmpty == false {
                    let tcs = TaskCompletionSource<Void>()
                    tasks.append(tcs.task)
                    
                    let batchFetch = CKFetchRecordsOperation(recordIDs: queryRecordIDs)
                    batchFetch.database = self.database
                    batchFetch.perRecordCompletionBlock = { (record, recordID, error) in
                        if let e = error {
                            debugPrint(e)
                            return
                        }
                        
                        if recordID == projectRecordID {
                            plan.project = KNOTProjectEntity(from: record!)
                        } else {
                            let item = KNOTPlanItemEntity(from: record!)
                            plan.items?.append(item)
                        }
                    }
                    batchFetch.fetchRecordsCompletionBlock = { (records, error) in
                        if let e = error {
                            tcs.set(error: e)
                        } else {
                            tcs.set(result: ())
                        }
                    }
                    batchFetch.start()
                }
            }
            
            queryTcs.set(result: ())
        }
        return Task<Void>.whenAll(tasks).continueWith(Executor.mainThread) {
            if $0.error != nil {
                throw $0.error!
            }
            self.plansSubject.publish((plans, .reset, nil))
        }
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
        return KNOTPlanDetailModelImpl(plan: plan)
    }
}

private class KNOTPlanDetailModelImpl: KNOTPlanDetailModel {
    let plan: KNOTPlanEntity
    
    init(plan: KNOTPlanEntity) {
        self.plan = plan
    }
}

extension String: Error {
}
