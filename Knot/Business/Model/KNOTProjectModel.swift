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
    
    func loadItems(completion: @escaping (Error?) -> ())
    func add(project: KNOTProjectEntity, completion: @escaping (KNOTProjectItemModel?, Error?) -> ())
    func delete(project: KNOTProjectEntity, completion: @escaping (Error?) -> ())
}

class KNOTProjectModelImpl: KNOTProjectModel {
    
    private let metadataQuery: NSMetadataQuery  = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [ NSMetadataQueryUbiquitousDocumentsScope ]
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
    
    private func containerURL() throws -> URL? {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            let error = NSError(domain: "KNOTProjectModelLoadError", code: 0, userInfo: [ NSLocalizedDescriptionKey : "No login to iCloud" ]);
            throw error
        }
        
        return URL(fileURLWithPath: "Documents", relativeTo: url)
    }
    
    var items: [KNOTProjectItemModel]? {
        return _items
    }
    
    func loadItems(completion: @escaping (Error?) -> ()) {
        do {
            _ = try containerURL()
        } catch let error {
            completion(error)
        }
        
        loadCompletion = completion
        if !metadataQuery.start() {
            print("false")
        }
    }
    
    func add(project: KNOTProjectEntity, completion: @escaping (KNOTProjectItemModel?, Error?) -> ()) {
        do {
            guard let container = try containerURL() else {
                return
            }
           
            let data = try JSONEncoder().encode(project)
            
            let fileURL = project.urlForContainer(container)
            try data.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
            
            let itmeModel = KNOTProjectItemModelImpl(fileURL: fileURL, projectEntity: project)
            
            _items?.insert(itmeModel, at: 0)
            completion(itmeModel, nil)
        } catch let error {
            completion(nil, error)
            return
        }
    }
    
    func delete(project: KNOTProjectEntity, completion: @escaping (Error?) -> ()) {
        do {
            guard let container = try containerURL() else {
                return
            }
            
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
                        }
                    }
                }
                
                fileCoordinator.coordinate(writingItemAt: fileURL, options: [ .forDeleting ], error: &error) {
                    do {
                        try FileManager.default.removeItem(at: $0)
                        mainThreadCompletion(nil)
                    } catch let error {
                        mainThreadCompletion(error)
                    }
                }
                
                if error != nil {
                    mainThreadCompletion(error)
                }
            }
        } catch let error {
            completion(error)
        }
    }
}

extension KNOTProjectEntity {
    func urlForContainer(_ container: URL) -> URL {
        return URL(fileURLWithPath: "\(UInt64(createDate.timeIntervalSince1970 * 1000))", relativeTo: container)
    }
}
