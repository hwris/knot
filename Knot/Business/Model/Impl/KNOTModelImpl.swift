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
    
    let plansSubject = Subject<[KNOTPlanEntity]>()
    let projectsSubject = Subject<[KNOTProjectEntity]>()
    
    var planModel: KNOTPlanModel { self }
    var projectModel: KNOTProjectModel { self }
    var searchModel: KNOTSearchModel { self }
    
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
            self.plansSubject.publish(planTask.result as? [KNOTPlanEntity])
            
            let planToProject = getPlanToProject()
            planTask.result?.forEach {
                let plan = $0 as! KNOTPlanEntity
                plan.project = planToProject[plan.ckRecordID]
                planToProject[plan.ckRecordID]?.plans?.append(plan)
            }
            
            self.projectsSubject.publish(projectTask.result as? [KNOTProjectEntity])
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
    
    private func _loadProjects(_ getPlanToProject: inout (() -> ([CKRecord.ID : KNOTProjectEntity]))?) -> Task<[KNOTEntityBase]> {
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
    
    private func updatePlanLocal(_ plan: KNOTPlanEntity, _ plansSubject: Subject<[KNOTPlanEntity]>) {
        var plans = plansSubject.value ?? []
        if !plans.contains(plan) {
            plans.append(plan)
        }
        plansSubject.publish(plans)
    }
    
    private func updatePlanRecord(_ plan: KNOTPlanEntity) -> Task<Void> {
        let records = [ plan.ckRecord ] + (plan.items?.map({ $0.ckRecord }) ?? [])
        return startModifyRecordsOperation(recordsToSave: records)
        { (_records, _recordIDs, _error) in
            if let records = _records {
                plan.ckRecord = records.first(where: { $0.recordID == plan.ckRecordID })!
                plan.items?.forEach({ (item) in item.ckRecord = records.first(where: { $0.recordID == item.ckRecordID })! })
            }
            return _error
        }
    }
    
    private func deletePlanLocal(_ plan: KNOTPlanEntity,
                                 _ plansSubject: Subject<[KNOTPlanEntity]>) {
        if var plans = plansSubject.value {
            plans.removeAll { $0 == plan }
            plansSubject.publish(plans)
        }
    }
    
    private func deletePlanRecord(_ plan: KNOTPlanEntity) -> Task<Void> {
        let records = [ plan.ckRecordID ] + (plan.items?.map({ $0.ckRecordID }) ?? [])
        return startModifyRecordsOperation(recordIDsToDelete: records,
                                           modifyRecordsCompletionBlock: nil)
    }
    
    private func updateProjectLocal(_ proj: KNOTProjectEntity,
                                    _ projectsSubject: Subject<[KNOTProjectEntity]>) {
        var projs = projectsSubject.value ?? []
        if !projs.contains(proj) {
            projs.append(proj)
        }
        projectsSubject.publish(projs)
    }
    
    private func updateProjectRecord(_ proj: KNOTProjectEntity) -> Task<Void> {
        let records = [ proj.ckRecord ]
        return startModifyRecordsOperation(recordsToSave: records)
        { (_records, _recordIDs, _error) in
            if let records = _records {
                proj.ckRecord = records.first(where: { $0.recordID == proj.ckRecordID })!
            }
            return _error
        }
    }
    
    private func deleteProjectLocal(_ proj: KNOTProjectEntity,
                                    _ projectsSubject: Subject<[KNOTProjectEntity]>) {
        if var projs = projectsSubject.value {
            projs.removeAll { $0 == proj }
            projectsSubject.publish(projs)
        }
    }
    
    private func deleteProjectRecord(_ proj: KNOTProjectEntity) -> Task<Void> {
        let records = [ proj.ckRecordID ] + (proj.plans?.filter{ $0.isOnlyInProject }.map{ $0.ckRecordID } ?? [])
        return startModifyRecordsOperation(recordIDsToDelete: records,
                                           modifyRecordsCompletionBlock: nil);
    }
    
    private func startModifyRecordsOperation(recordsToSave: [CKRecord]? = nil,
                                             recordIDsToDelete: [CKRecord.ID]? = nil,
                                             modifyRecordsCompletionBlock: (([CKRecord]?, [CKRecord.ID]?, Error?) -> Error?)?)
    -> Task<Void> {
        let tcs = TaskCompletionSource<Void>()
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave,
                                                       recordIDsToDelete: recordIDsToDelete)
        modifyOperation.database = database
        modifyOperation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            DispatchQueue.main.async {
                if let e = modifyRecordsCompletionBlock != nil ?
                    modifyRecordsCompletionBlock!(records, recordIDs, error) :
                    error {
                    tcs.set(error: e)
                } else {
                    tcs.set(result: ())
                }
            }
        }
        modifyOperation.start()
        
        return tcs.task
    }
}

extension KNOTModelImpl: KNOTPlanModel {
    func loadPlans() -> Task<Void> {
        loadData()
    }
    
    func plans(onDay day: Date) -> [KNOTPlanEntity] {
        guard let plans = plansSubject.value else {
            return []
        }
        
        let calendar = Calendar.current
        let targetDateComponents = calendar.dateComponents([ .year, .month, .day ], from: day)
        let items = plans.filter {
            guard let remindDate = $0.remindDate else {
                return false
            }
            
            let planDateComponents = calendar.dateComponents([ .year, .month, .day ], from: remindDate)
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
        updatePlanLocal(plan, plansSubject)
        if let proj = plan.project {
            updateProjectLocal(proj, projectsSubject)
        }
        return updatePlanRecord(plan)
    }
    
    func deletePlan(_ plan: KNOTPlanEntity) -> Task<Void> {
        var updateTask: Task<Void>?
        if let proj = plan.project {
            proj.plans?.removeAll { $0 == plan }
            updateProjectLocal(proj, projectsSubject)
            updateTask = updateProjectRecord(proj)
        }
        deletePlanLocal(plan, plansSubject)
        
        let deleteTask = deletePlanRecord(plan)
        return (updateTask != nil) ?
            Task.whenAll([ deleteTask, updateTask! ]) :
            deleteTask
    }
    
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel {
        KNOTPlanDetailModelImpl(plan: plan, knotModel: self)
    }
    
    func planMoreModel(with plan: KNOTPlanEntity) -> KNOTPlanMoreModel {
        KNOTPlanMoreModelImpl(plan: plan, knotModel: self)
    }
}

extension KNOTModelImpl: KNOTProjectModel {
    func loadProjects() -> Task<Void> {
        loadData()
    }
    
    func updateProject(_ proj: KNOTProjectEntity) -> Task<Void> {
        updateProjectLocal(proj, projectsSubject)
        return updateProjectRecord(proj)
    }
    
    func deleteProject(_ proj: KNOTProjectEntity) -> Task<Void> {
        deleteProjectLocal(proj, projectsSubject)
        return deleteProjectRecord(proj)
    }
    
    func projectDetailModel(with proj: KNOTProjectEntity) -> KNOTProjectDetailModel {
        KNOTProjectDetailModelImpl(project: proj, knotModel: self)
    }
    
    func projectPlansModel(with proj: KNOTProjectEntity) -> KNOTPlanModel {
        class ProjectPlanModel: KNOTPlanModel {
            private let knotModel: KNOTModelImpl
            private let proj: KNOTProjectEntity
            
            var plansSubject: Subject<[KNOTPlanEntity]> { knotModel.plansSubject }
            
            init(knotModel: KNOTModelImpl, proj: KNOTProjectEntity) {
                self.knotModel = knotModel
                self.proj = proj
            }
            
            func loadPlans() -> Task<Void> {
                return Task(())
            }
            
            func plans(onDay day: Date) -> [KNOTPlanEntity] {
                return proj.plans ?? []
            }
            
            func updatePlan(_ plan: KNOTPlanEntity) -> Task<Void> {
                var isInsert = false
                if proj.plans?.contains(plan) != true {
                    plan.markOnlyInProject()
                    let _ = knotModel.add(plan, to: proj)
                    isInsert = true
                }
                
                return knotModel.updatePlan(plan).continueOnSuccessWithTask {
                    return isInsert ?
                    self.knotModel.updateProjectRecord(self.proj) :
                    Task(())
                }
            }
            
            func deletePlan(_ plan: KNOTPlanEntity) -> Task<Void> {
                knotModel.deletePlan(plan)
            }
            
            func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel {
                class ProjectPlanDetailModel: KNOTPlanDetailModelImpl {
                    private let projectPlanModel: ProjectPlanModel
                    
                    init(plan: KNOTPlanEntity,
                         projectPlanModel: ProjectPlanModel) {
                        self.projectPlanModel = projectPlanModel
                        super.init(plan: plan, knotModel: projectPlanModel.knotModel)
                    }
                    
                    override func updatePlan() -> Task<Void> {
                        projectPlanModel.updatePlan(plan)
                    }
                }
                
                return ProjectPlanDetailModel(plan: plan, projectPlanModel: self)
            }
            
            func planMoreModel(with plan: KNOTPlanEntity) -> KNOTPlanMoreModel {
                KNOTPlanMoreModelImpl(plan: plan, knotModel: knotModel)
            }
        }
        return ProjectPlanModel(knotModel: self, proj: proj)
    }
    
    func projectMoreModel(with proj: KNOTProjectEntity) -> KNOTProjectMoreModel {
        KNOTProjectDetailModelImpl(project: proj, knotModel: self)
    }
    
    fileprivate func sync(_ plan: KNOTPlanEntity, to proj: KNOTProjectEntity) -> Task<Void> {
        if !add(plan, to: proj) {
            return Task(())
        }
        updateProjectLocal(proj, projectsSubject)
        return updateProjectRecord(proj)
    }
    
    private func add(_ plan: KNOTPlanEntity, to proj: KNOTProjectEntity) -> Bool {
        if let plans = proj.plans, plans.contains(plan) {
            return false
        }
        
        if proj.plans == nil {
            proj.plans = []
        }
        
        proj.plans?.append(plan)
        plan.project = proj
        return true
    }
}

extension KNOTModelImpl: KNOTSearchModel {
    func search(with text: String) -> ([KNOTPlanEntity], [KNOTProjectEntity]) {
        let planResult = plansSubject.value?.filter {
            $0.content.contains(text) ||
                (($0.items?.contains(where: { $0.content.contains(text) })) == true)
        }
        let projResult = projectsSubject.value?.filter {
            $0.name.contains(text)
        }
        return (planResult ?? [], projResult ?? [])
    }
}

private class KNOTPlanDetailModelImpl: KNOTPlanDetailModel {
    let originPlan: KNOTPlanEntity
    let plan: KNOTPlanEntity
    fileprivate let knotModel: KNOTModelImpl
    
    init(plan: KNOTPlanEntity, knotModel: KNOTModelImpl) {
        originPlan = KNOTPlanEntity(entity: plan)
        self.plan = plan
        self.knotModel = knotModel
    }
    
    var flagColor: UInt32 {
        get {
            return plan.flagColor
        }
        
        set {
            plan.flagColor = newValue
        }
    }
    
    func updatePlan() -> Task<Void> {
        knotModel.updatePlan(plan)
    }
    
    var needUpdate: Bool {
        originPlan.isAbsolutelyEqual(plan) == false
    }
}

private class KNOTPlanMoreModelImpl: KNOTPlanDetailModelImpl,
                                     KNOTProjectPlanMoreModel,
                                     KNOTProjectSyncToPlanModel,
                                     KNOTPlanSyncToProjModel {
    func deletePlan() -> Task<Void> {
        knotModel.deletePlan(plan)
    }
    
    var projs: [KNOTProjectEntity] {
        knotModel.projectsSubject.value ?? []
    }
    
    var syncToProjModel: KNOTPlanSyncToProjModel {
        self
    }
    
    var syncToPlanModel: KNOTProjectSyncToPlanModel {
        self
    }
    
    func syncPlanTo(_ proj: KNOTProjectEntity) -> Task<Void> {
        knotModel.sync(plan, to: proj)
    }
    
    func syncToDate(_ date: Date) -> Task<Void> {
        //todo
//        if !plan.isOnlyInProject {
//            return Task(error: "It has been added to the plan.")
//        }
        plan.remindDate = date
        return knotModel.updatePlan(plan)
    }
}

private class KNOTProjectDetailModelImpl: KNOTProjectDetailModel, KNOTProjectMoreModel {
    let originProject: KNOTProjectEntity
    let project: KNOTProjectEntity
    fileprivate let knotModel: KNOTModelImpl
    
    init(project: KNOTProjectEntity, knotModel: KNOTModelImpl) {
        originProject = KNOTProjectEntity(entity: project)
        self.project = project
        self.knotModel = knotModel
    }
    
    var flagColor: UInt32 {
        get {
            return project.flagColor
        }
        
        set {
            project.flagColor = newValue
        }
    }
    
    func updateProject() -> Task<Void> {
        knotModel.updateProject(project)
    }
    
    func deleteProject() -> Task<Void> {
        knotModel.deleteProject(project)
    }
    
    var needUpdate: Bool {
        originProject.isAbsolutelyEqual(project) == false
    }
}

private extension KNOTPlanEntity {
    var isOnlyInProject: Bool {
        return remindDate == nil
    }
    
    func markOnlyInProject() {
        remindDate = nil
    }
}

extension String: Error {}
