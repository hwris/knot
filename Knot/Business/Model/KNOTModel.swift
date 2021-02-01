//
//  KNOTModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation
import BoltsSwift

private let SearchPredicate = "%K LIKE '*/TodoList/*'"
private let PlanFileType = "plan"
private let ProjectFileType = "project"

protocol KNOTModel {
    var planModel: KNOTPlanModel { get }
}

class KNOTModelImpl: KNOTModel {
    private let metadataQuery: NSMetadataQuery  = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [ NSMetadataQueryUbiquitousDocumentsScope ]
        metadataQuery.predicate = NSPredicate(format: SearchPredicate, NSMetadataItemPathKey)
        return metadataQuery
    }()
    private var loadCompletions = [TaskCompletionSource<Void>]()
    
    let plansSubject = Subject<CollectionSubscription<[KNOTPlanEntity]>>()
    let projectsSubject = Subject<CollectionSubscription<[KNOTProjectEntity]>>()
    
    var planModel: KNOTPlanModel { self }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentsDidUpdated(notification:)),
                                               name: .NSMetadataQueryDidFinishGathering,
                                               object: metadataQuery)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentsDidUpdated(notification:)),
                                               name: .NSMetadataQueryDidUpdate,
                                               object: metadataQuery)
    }
    
    private func containerURL() throws -> URL {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw "No login to iCloud"
        }
        
        let containerURL = URL(fileURLWithPath: "Documents/TodoList", relativeTo: url)
        
        if FileManager.default.fileExists(atPath: containerURL.absoluteURL.path) == false {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return containerURL
    }
    
    private func loadItems() throws -> Task<Void> {
        if plansSubject.value != nil || projectsSubject.value != nil {
            return Task(())
        }
        
        _ = try containerURL()
        
        let isSuccess = metadataQuery.start()
        if !isSuccess {
            throw "Data loading failed"
        }
        
        let tcs = TaskCompletionSource<Void>()
        loadCompletions.append(tcs)
        return tcs.task
    }
    
    @objc private func contentsDidUpdated(notification: Notification) {
        let completion = { (error: Error?) -> () in
            self.loadCompletions.forEach { if let e = error { $0.set(error: e) } else { $0.set(result: ()) } }
            self.loadCompletions.removeAll()
        }
        
        guard let metadatas = (metadataQuery.results as? [NSMetadataItem])?.map({ $0.value(forAttribute: NSMetadataItemURLKey) }) as? [URL] else {
            completion("Date error!")
            return
        }
        
        let planTasks = metadatas.filter({ $0.pathExtension == PlanFileType })
            .map({ self.fileCoordinate(readingItemAt: $0, options: .withoutChanges) {
                return try KNOTPlanEntity.fromJSONData(Data(contentsOf: $0))
                }})
        let projectTasks = metadatas.filter({ $0.pathExtension == ProjectFileType })
            .map({ self.fileCoordinate(readingItemAt: $0, options: .withoutChanges) {
                return try KNOTProjectEntity.fromJSONData(Data(contentsOf: $0))
                }})
        
        Task.whenAllResult(planTasks).continueWith { [weak self] (t) -> Any? in
            debugPrint("load plans:", t.error ?? "", t.result ?? "")
            self?.plansSubject.publish((t.result?.compactMap { $0 }, .reset))
            return t
        }
        
        Task.whenAllResult(projectTasks).continueWith { [weak self] (t) -> Any? in
            debugPrint("load projects:", t.error ?? "", t.result ?? "")
            self?.projectsSubject.publish((t.result?.compactMap { $0 }, .reset))
            return t
        }
    }
}

extension KNOTModelImpl {
    fileprivate func fileCoordinate<T>(readingItemAt url: URL,
                                       options: NSFileCoordinator.ReadingOptions = [],
                                       byAccessor reader: @escaping (URL) throws -> T) -> Task<T> {
        return fileCoordinate { (fileCoordinator, error, tcs) in
            fileCoordinator.coordinate(readingItemAt: url, options: options, error: error) {
                do {
                    tcs.set(result: try reader($0))
                } catch let e {
                    tcs.set(error: e)
                }
            }
        }
    }
    
    fileprivate func fileCoordinate<T>(writingItemAt url: URL,
                                       options: NSFileCoordinator.WritingOptions = [],
                                       byAccessor writer: @escaping (URL) throws -> T) -> Task<T> {
        return fileCoordinate { (fileCoordinator, error, tcs) in
            fileCoordinator.coordinate(writingItemAt: url, options: options, error: error) {
                do {
                    tcs.set(result: try writer($0))
                } catch let e {
                    tcs.set(error: e)
                }
            }
        }
    }
    
    fileprivate func fileCoordinate<T>(byAccessor accessor: @escaping (NSFileCoordinator, NSErrorPointer, TaskCompletionSource<T>) throws -> Void) -> Task<T> {
        let task = Task<Task<T>>(Executor.queue(DispatchQueue.global()), closure: {
            let fileCoordinator = NSFileCoordinator()
            var error: NSError?
            let tcs = TaskCompletionSource<T>()
            try accessor(fileCoordinator, &error, tcs)
            if let e = error {
                tcs.set(error: e)
            }
            return tcs.task
        })
        
        return task.continueWith(Executor.mainThread) { (t) -> T in
            let result = t.result!
            if let e = result.error {
                throw e
            }
            return result.result!
        }
    }
}

extension KNOTModelImpl: KNOTPlanModel {
    func loadPlans() throws -> Task<Void> {
        return try loadItems()
    }
    
    func deletePlan(_ plan: KNOTPlanEntity) throws -> Task<Void> {
        let container = try containerURL()
        
        var plans = plansSubject.value?.0
        plans?.removeAll { $0 == plan }
        plansSubject.publish((plans, .remove))
        
        return fileCoordinate(writingItemAt: plan.fileURL(for: container), options: .forMerging) {
            try FileManager.default.removeItem(at: $0)
        }
    }
    
    func insertPlan(at index: Int) throws -> KNOTPlanDetailModel {
        let container = try containerURL()
        let plan = KNOTPlanEntity(creationDate: Date(), priority: Int64(index), content: "", flagColor: 0x5276FF)
        let index = Int(plan.priority)
        var plans = plansSubject.value?.0 ?? []
        plans.insert(plan, at: index)
        
        var updateTasks = [Task<Void>]()
        if index + 1 < plans.endIndex {
            let changedRange = index+1..<plans.endIndex
            changedRange.forEach { plans[$0].priority = Int64($0) }
            updateTasks = try plans[changedRange].map({ try _updatePlan($0) })
        }
        
        let insertTask = fileCoordinate(writingItemAt: plan.fileURL(for: container)) {
            let data = try plan.toJsonData()
            try data.write(to: $0)
        }
        
        plansSubject.publish((plans, .insert))
        
        updateTasks.append(insertTask)
        Task.whenAll(updateTasks).continueWith { (t) -> Void in
            if let error = t.error {
                assert(false, "\(error)")
            }
        }
        
        return KNOTPlanDetailModelImpl(plan: plan)
    }
    
    func updatePlan(_ plan: KNOTPlanEntity) throws -> Task<Void> {
        let plans = plansSubject.value?.0
        plansSubject.publish((plans, .update))
        return try _updatePlan(plan)
    }
    
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel {
        return KNOTPlanDetailModelImpl(plan: plan)
    }
    
    func _updatePlan(_ plan: KNOTPlanEntity) throws -> Task<Void> {
        return self.fileCoordinate(writingItemAt: plan.fileURL(for: try containerURL()), options: .forMerging) {
            try plan.toJsonData().write(to: $0)
        }
    }
}

extension KNOTPlanEntity {
    func fileURL(for container: URL) -> URL {
        return URL(fileURLWithPath: "\(Int64(creationDate.timeIntervalSince1970 * 1000))", relativeTo: container).appendingPathExtension(PlanFileType)
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
