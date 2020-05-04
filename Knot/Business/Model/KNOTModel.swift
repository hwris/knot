//
//  KNOTModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

private let SearchPredicate = "%K LIKE '*/TodoList/*.json'"
private let PlanFileType = ".plan"
private let ProjectFileType = ".project"

protocol KNOTModel {
    var planModel: KNOTPlanModel { get }
}

class KNOTModelImpl: KNOTModel, KNOTPlanModel {
    
    private let metadataQuery: NSMetadataQuery  = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [ NSMetadataQueryUbiquitousDocumentsScope ]
        metadataQuery.predicate = NSPredicate(format: SearchPredicate, NSMetadataItemPathKey)
        return metadataQuery
    }()
    
    let plansSubject = Subject<[KNOTDocument<KNOTPlanEntity>]>()
    let projectsSubject = Subject<[KNOTDocument<KNOTPlanEntity>]>()
    
    var planModel: KNOTPlanModel { self }
    
    private var loadCompletions = [((Error?) -> ())]()
    
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
    
    func loadItems(completion: @escaping (Error?) -> ()) throws {
        if plansSubject.value != nil || projectsSubject.value != nil {
            completion(nil)
            return
        }
        
        _ = try containerURL()
        
        let isSuccess = metadataQuery.start()
        if isSuccess {
            loadCompletions.append(completion)
        } else {
            throw NSError(domain: "KNOTModelLoadItemsErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Data loading failed" ])
        }
    }
    
    private func containerURL() throws -> URL {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            let error = NSError(domain: "KNOTModelContainerURLErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "No login to iCloud" ])
            throw error
        }
        
        let containerURL = URL(fileURLWithPath: "Documents/TodoList", relativeTo: url)
        
        if FileManager.default.fileExists(atPath: containerURL.absoluteURL.path) == false {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return containerURL
    }
    
    @objc private func contentsDidUpdated(notification: Notification) {
        let completion = { (error: Error?) -> () in
            self.loadCompletions.forEach({ $0(error) })
            self.loadCompletions.removeAll()
        }
        
        guard let metadatas = (metadataQuery.results as? [NSMetadataItem])?.map({ ($0.value(forAttribute: NSMetadataItemURLKey), $0.value(forAttribute: NSMetadataItemFSCreationDateKey)) }) as? [(URL, Date)] else {
            let error = NSError(domain: "KNOTModelUpdateURLErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Date error!" ])
            completion(error)
            return
        }
        
        var plans = [KNOTDocument<KNOTPlanEntity>]()
        var projects = [KNOTDocument<KNOTPlanEntity>]()
        
        metadatas.forEach { (url, creationDate) in
            let contentPriority = Int64(url.lastPathComponent)!
            
            if url.pathExtension == PlanFileType {
                plans.append(KNOTDocument(fileURL: url,
                                          creationDate: creationDate,
                                          contentPriority: contentPriority))
            }
            
            if url.pathExtension == ProjectFileType {
                projects.append(KNOTDocument(fileURL: url,
                                             creationDate: creationDate,
                                             contentPriority: contentPriority))
            }
        }
        
        plansSubject.publish(plans)
        projectsSubject.publish(projects)
        
        completion(nil)
    }
    
//    func add(project: KNOTProjectEntity, completion: @escaping (KNOTProjectItemModel?, Error?) -> ()) throws {
//        let container = try containerURL()
//        let fileURL = project.urlForContainer(container)
//
//        DispatchQueue.global(qos: .default).async { [weak self] in
//            do {
//                let data = try JSONEncoder().encode(project)
//                try data.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
//
//                DispatchQueue.main.async {
//                    let itmeModel = KNOTProjectItemModelImpl(fileURL: fileURL, projectEntity: project)
//                    self?._items?.insert(itmeModel, at: 0)
//                    completion(itmeModel, nil)
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    completion(nil, error)
//                }
//            }
//        }
//    }
//
//    func delete(project: KNOTProjectEntity, completion: @escaping (Error?) -> ()) throws {
//        let container = try containerURL()
//        let fileURL = project.urlForContainer(container)
//
//        DispatchQueue.global(qos: .default).async { [weak self] in
//            let fileCoordinator = NSFileCoordinator()
//            var error: NSError?
//
//            let mainThreadCompletion = { (error: Error?) -> () in
//                DispatchQueue.main.async {
//                    if error != nil {
//                        completion(error)
//                    } else {
//                        guard let _self = self, let _items = _self._items else {
//                            return
//                        }
//
//                        _self._items = _items.filter({ $0.fileURL == fileURL })
//                        completion(nil)
//                    }
//                }
//            }
//
//            fileCoordinator.coordinate(writingItemAt: fileURL, options: [ .forDeleting ], error: &error) {
//                do {
//                    try FileManager.default.removeItem(at: $0)
//                    mainThreadCompletion(nil)
//                } catch {
//                    mainThreadCompletion(error)
//                }
//            }
//
//            if error != nil {
//                mainThreadCompletion(error)
//            }
//        }
//    }
}
