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
        let query = CKQuery(recordType: KNOTPlanEntity.recordType, predicate: NSPredicate(value: true))
        let queryTcs = TaskCompletionSource<Void>()
        database.perform(query, inZoneWith: nil) { (results, error) in
            guard error == nil else {
                queryTcs.set(error: error!)
                return
            }
            
            guard let records = results, records.isEmpty == false else {
                queryTcs.set(result: ())
                return
            }
            
            var batchFetchIDs = [CKRecord.ID]()
            var itemToPlan = [CKRecord.ID : KNOTPlanEntity]()
            var projectToPlan = [CKRecord.ID : KNOTPlanEntity]()
            for record in records {
                var itemRecordIDs: [CKRecord.ID]?
                var projectRecordID: CKRecord.ID?
                let plan = KNOTPlanEntity(from: record, itemRecordIDs: &itemRecordIDs, projectRecordID: &projectRecordID)
                plans.append(plan)
                
                if let ids = itemRecordIDs {
                    plan.items = []
                    batchFetchIDs.append(contentsOf: ids)
                    ids.forEach { itemToPlan[$0] = plan }
                }
                if let id = projectRecordID {
                    batchFetchIDs.append(id)
                    projectToPlan[id] = plan
                }
            }
            
            guard batchFetchIDs.isEmpty == false else {
                queryTcs.set(result: ())
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
                
                if let plan = itemToPlan[id] {
                    plan.items?.append(KNOTPlanItemEntity(from: record!))
                } else if let plan = projectToPlan[id] {
                    plan.project = KNOTProjectEntity(from: record!)
                }
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
                    queryTcs.set(result: ())
                }
            }
        }
        return queryTcs.task.continueWith(Executor.mainThread) {
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
        return KNOTPlanEditModelImpl(plan: plan)
    }
    
    func planMoreModel(with plan: KNOTPlanEntity) -> KNOTPlanMoreModel {
        return KNOTPlanEditModelImpl(plan: plan)
    }
}

private class KNOTPlanEditModelImpl: KNOTPlanDetailModel, KNOTPlanMoreModel {
    let plan: KNOTPlanEntity
    
    init(plan: KNOTPlanEntity) {
        self.plan = plan
    }
}

extension String: Error {
}