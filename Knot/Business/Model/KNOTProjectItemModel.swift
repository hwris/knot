//
//  KNOTProjectItemModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/28.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

protocol KNOTProjectItemModel {
    
    var projectEntity: KNOTProjectEntity? { get }
    
    func loadEntity(completion: ((Bool) -> ())?) throws
    func beginEditing() throws
    func save(completion: (Error) -> ()) throws
    func endEditing() throws
}

class KNOTProjectItemModelImpl : KNOTProjectItemModel {
    let fileURL: URL
    
    fileprivate(set) var projectEntity: KNOTProjectEntity?
    private var doc: KNOTProjectItemDocument?
    
    init(fileURL: URL, projectEntity: KNOTProjectEntity? = nil) {
        self.fileURL = fileURL
        self.projectEntity = projectEntity
    }
    
    func loadEntity(completion: ((Bool) -> ())?) throws {
        let doc = KNOTProjectItemDocument(project: self)
        doc.open(completionHandler: completion)
    }
    
    func beginEditing() throws {
        doc = KNOTProjectItemDocument(project: self)
        doc?.open(completionHandler: nil)
    }
    
    func save(completion: (Error) -> ()) throws {
        doc?.updateChangeCount(.done)
    }
    
    func endEditing() throws {
        doc?.close(completionHandler: nil)
        doc = nil
    }
}
 
private class KNOTProjectItemDocument: UIDocument {
    private var project: KNOTProjectItemModelImpl
    
    init(project: KNOTProjectItemModelImpl) {
        self.project = project
        super.init(fileURL: project.fileURL)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw NSError(domain: "KNOTProjectItemDocumentLoadErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Data is invalid" ])
        }
        let projectEntity = try JSONDecoder().decode(KNOTProjectEntity.self, from: data)
        project.projectEntity = projectEntity
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let projectEntity = project.projectEntity else {
            throw NSError(domain: "KNOTProjectItemDocumentWriteErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "No content can be saved" ])
        }
        return try JSONEncoder().encode(projectEntity)
    }
    
    override func read(from url: URL) throws {
        try super.read(from: url)
    }
    
    override func writeContents(_ contents: Any, to url: URL, for saveOperation: UIDocument.SaveOperation, originalContentsURL: URL?) throws {
        try super.writeContents(contents, to: url, for: saveOperation, originalContentsURL: originalContentsURL)
    }
    
    override func writeContents(_ contents: Any, andAttributes additionalFileAttributes: [AnyHashable : Any]? = nil, safelyTo url: URL, for saveOperation: UIDocument.SaveOperation) throws {
        try super.writeContents(contents, andAttributes: additionalFileAttributes, safelyTo: url, for: saveOperation)
    }
    
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
    
    override func finishedHandlingError(_ error: Error, recovered: Bool) {
        super.finishedHandlingError(error, recovered: recovered)
    }
    
    override func userInteractionNoLongerPermitted(forError error: Error) {
        super.userInteractionNoLongerPermitted(forError: error)
    }
    
    override var hasUnsavedChanges: Bool {
        return super.hasUnsavedChanges
    }
}
