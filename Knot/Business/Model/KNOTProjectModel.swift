//
//  KNOTProjectModelImpl.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

protocol KNOTProjectModel {
    
    var items: [KNOTProjectItemModel]? { get }
    
    func loadItems(completion: @escaping (Error?) -> ()) throws
    func add(project: KNOTProjectEntity, completion: @escaping (KNOTProjectItemModel?, Error?) -> ()) throws
    func delete(project: KNOTProjectEntity, completion: @escaping (Error?) -> ()) throws
}

class KNOTProjectModelImpl: KNOTProjectModel {
    private let metadataQuery: NSMetadataQuery  = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [ NSMetadataQueryUbiquitousDocumentsScope ]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*/TodoList/*.json'", NSMetadataItemPathKey)
        return metadataQuery
    }()
    
    private(set) var _items: [KNOTProjectItemModelImpl]?
    private var loadCompletion: ((Error?) -> ())?
     
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(projectsDidUpdated(notification:)),
                                               name: .NSMetadataQueryDidFinishGathering,
                                               object: metadataQuery)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(projectsDidUpdated(notification:)),
                                               name: .NSMetadataQueryDidUpdate,
                                               object: metadataQuery)
    }
    
    @objc private func projectsDidUpdated(notification: Notification) {
        _items = (metadataQuery.results as? [NSMetadataItem])?.map({ KNOTProjectItemModelImpl(fileURL: ($0.value(forAttribute: NSMetadataItemURLKey)) as! URL) })
        loadCompletion?(nil)
        loadCompletion = nil
    }
    
    private func containerURL() throws -> URL {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            let error = NSError(domain: "KNOTProjectModelContainerURLErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "No login to iCloud" ]);
            throw error
        }
        
        let containerURL = URL(fileURLWithPath: "Documents/TodoList", relativeTo: url)
        
        if FileManager.default.fileExists(atPath: containerURL.absoluteURL.path) == false {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return containerURL
    }
    
    var items: [KNOTProjectItemModel]? {
        return _items
    }
    
    func loadItems(completion: @escaping (Error?) -> ()) throws {
        _ = try containerURL()
        
        let isSuccess = metadataQuery.start()
        if isSuccess {
            loadCompletion = completion
        } else {
            throw NSError(domain: "KNOTProjectModelloadItemsErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Data loading failed" ]);
        }
    }
    
    func add(project: KNOTProjectEntity, completion: @escaping (KNOTProjectItemModel?, Error?) -> ()) throws {
        let container = try containerURL()
        let fileURL = project.urlForContainer(container)
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            do {
                let data = try JSONEncoder().encode(project)
                try data.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
                
                DispatchQueue.main.async {
                    let itmeModel = KNOTProjectItemModelImpl(fileURL: fileURL, projectEntity: project)
                    self?._items?.insert(itmeModel, at: 0)
                    completion(itmeModel, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    func delete(project: KNOTProjectEntity, completion: @escaping (Error?) -> ()) throws {
        let container = try containerURL()
        let fileURL = project.urlForContainer(container)
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            let fileCoordinator = NSFileCoordinator()
            var error: NSError?
            
            let mainThreadCompletion = { (error: Error?) -> () in
                DispatchQueue.main.async {
                    if error != nil {
                        completion(error)
                    } else {
                        guard let _self = self, let _items = _self._items else {
                            return
                        }
                        
                        _self._items = _items.filter({ $0.fileURL == fileURL })
                        completion(nil)
                    }
                }
            }
            
            fileCoordinator.coordinate(writingItemAt: fileURL, options: [ .forDeleting ], error: &error) {
                do {
                    try FileManager.default.removeItem(at: $0)
                    mainThreadCompletion(nil)
                } catch {
                    mainThreadCompletion(error)
                }
            }
            
            if error != nil {
                mainThreadCompletion(error)
            }
        }
    }
}

extension KNOTProjectEntity {
    func urlForContainer(_ container: URL) -> URL {
        return URL(fileURLWithPath: "\(UInt64(createDate.timeIntervalSince1970 * 1000)).json", relativeTo: container)
    }
}
