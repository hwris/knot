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
private let PlanFileType = ".plan"
private let ProjectFileType = ".project"

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
    
    let plansSubject = Subject<[KNOTPlanEntity]>()
    let projectsSubject = Subject<[KNOTProjectEntity]>()
    
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
            .map({ KNOTDocument<KNOTPlanEntity>(fileURL: $0) })
            .map({ doc in doc.loadContent().continueOnSuccessWith { _ in doc.content } })
        let projectTasks = metadatas.filter({ $0.pathExtension == ProjectFileType })
            .map({ KNOTDocument<KNOTProjectEntity>(fileURL: $0) })
            .map({ doc in doc.loadContent().continueOnSuccessWith { _ in doc.content } })
        
        Task.whenAllResult(planTasks).continueWith { [weak self] (t) -> Any? in
            print("load plans: ", t.error ?? "")
            self?.plansSubject.publish(t.result?.compactMap { $0 })
            return t
        }
        
        Task.whenAllResult(projectTasks).continueWith { [weak self] (t) -> Any? in
            print("load projects: ", t.error ?? "")
            self?.projectsSubject.publish(t.result?.compactMap { $0 })
            return t
        }
    }
}

extension KNOTModelImpl: KNOTPlanModel {
    
    func loadPlans() throws -> Task<Void> {
        return try loadItems()
    }
    
    func deletePlan(_ plan: KNOTPlanEntity) throws -> Task<Void> {
        let container = try containerURL()
        
        var plans = plansSubject.value ?? []
        plans.removeAll { $0 == plan }
        plansSubject.publish(plans)
        
        let fileURL = plan.fileURL(for: container)
        let task = Task(Executor.queue(DispatchQueue.global()), closure: {}).continueWith { _ -> Task<Void> in
            let fileCoordinator = NSFileCoordinator()
            
            let tcs = TaskCompletionSource<Void>()
            var error: NSError?
            fileCoordinator.coordinate(writingItemAt: fileURL, options: [ .forDeleting ], error: &error) {
                do {
                    try FileManager.default.removeItem(at: $0)
                    tcs.set(result: ())
                } catch let e {
                    tcs.set(error: e)
                }
            }
            
            if error != nil {
                tcs.set(error: error!)
            }
            
            return tcs.task
        }
        
        return task.result!
    }
    
    func emptyPlanDetailModel(at index: Int) -> KNOTPlanDetailModel {
        let planEntity = KNOTPlanEntity(creationDate: Date(), priority: Int64(index), content: "", flagColor: 0)
        return KNOTPlanDetailModelImpl(plan: planEntity, updateModel: self)
    }
    
    func planDetailModel(at index: Int) -> KNOTPlanDetailModel {
        return KNOTPlanDetailModelImpl(plan: plansSubject.value![index], updateModel: self)
    }
    
    func updatePlan(_ plan: KNOTPlanEntity) throws -> Task<Void> {
        let container = try containerURL()
        let index = Int(plan.priority)
        
        var plans = plansSubject.value ?? []
        
        if (plans.contains(plan)) {
            let doc = KNOTDocument<KNOTPlanEntity>(fileURL: plan.fileURL(for: container))
            return doc.save(content: plan).continueWith { (t) -> Void in
                if (t.result != true) {
                    throw "Update failed!"
                }
            }
        } else {
            plans.insert(plan, at: index)
            let changedRange = index..<plans.endIndex
            for i in changedRange {
                plans[i].priority = Int64(i)
            }
            plansSubject.publish(plans)
            
            let tasks = plans[changedRange].map({ (KNOTDocument<KNOTPlanEntity>(fileURL: $0.fileURL(for: container)), $0) })
                .map({ $0.0.save(content: $0.1) })
            return Task.whenAll(tasks)
        }
    }
}

extension KNOTPlanEntity {
    func fileURL(for container: URL) -> URL {
        return URL(fileURLWithPath: "\(Int64(creationDate.timeIntervalSince1970 * 1000))" + PlanFileType, relativeTo: container)
    }
}

private class KNOTPlanDetailModelImpl: KNOTPlanDetailModel {
    let plan: KNOTPlanEntity
    private weak var updateModel: (AnyObject & KNOTPlanUpdateModel)?
    
    init(plan: KNOTPlanEntity, updateModel: AnyObject & KNOTPlanUpdateModel) {
        self.plan = plan
        self.updateModel = updateModel
    }
    
    func updatePlan() throws -> Task<Void> {
        return try updateModel!.updatePlan(plan)
    }
}

extension String: Error {
}
