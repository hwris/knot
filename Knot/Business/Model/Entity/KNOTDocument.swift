//
//  KNOTDocument.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/28.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTDocument<T: Codable> {
    fileprivate let fileURL: URL
    let creationDate: Date
    let contentPriority: Int64
    let contentSubject: Subject<T>
    private var doc: KNOTDocumentInternal<T>?
   
    init(fileURL: URL, creationDate: Date, contentPriority: Int64, content: T? = nil) {
        self.fileURL = fileURL
        self.creationDate = creationDate
        self.contentPriority = contentPriority
        contentSubject = Subject(value: content)
    }
    
    func loadContent(completion: ((Bool) -> ())?) throws {
        let doc = KNOTDocumentInternal(docInfo: self)
        doc.open(completionHandler: completion)
    }
    
    func beginEditing() throws {
        doc = KNOTDocumentInternal(docInfo: self)
        doc?.open(completionHandler: nil)
    }
    
    func save(content: T) throws {
        contentSubject.publish(content)
        doc?.updateChangeCount(.done)
    }
    
    func endEditing() throws {
        doc?.close(completionHandler: nil)
        doc = nil
    }
}
     
private class KNOTDocumentInternal<T: Codable>: UIDocument {
    private weak var docInfo: KNOTDocument<T>?
    
    init(docInfo: KNOTDocument<T>) {
        self.docInfo = docInfo
        super.init(fileURL: docInfo.fileURL)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw NSError(domain: "KNOTDocumentLoadErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Data is invalid" ])
        }
        let content = try JSONDecoder().decode(T.self, from: data)
        docInfo?.contentSubject.publish(content)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let content = docInfo?.contentSubject.value else {
            throw NSError(domain: "KNOTDocumentWriteErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "No content can be saved" ])
        }
        return try JSONEncoder().encode(content)
    }
    
//    override func read(from url: URL) throws {
//        try super.read(from: url)
//    }
//
//    override func writeContents(_ contents: Any, to url: URL, for saveOperation: UIDocument.SaveOperation, originalContentsURL: URL?) throws {
//        try super.writeContents(contents, to: url, for: saveOperation, originalContentsURL: originalContentsURL)
//    }
//
//    override func writeContents(_ contents: Any, andAttributes additionalFileAttributes: [AnyHashable : Any]? = nil, safelyTo url: URL, for saveOperation: UIDocument.SaveOperation) throws {
//        try super.writeContents(contents, andAttributes: additionalFileAttributes, safelyTo: url, for: saveOperation)
//    }
//
//    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
//        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
//    }
//
//    override func finishedHandlingError(_ error: Error, recovered: Bool) {
//        super.finishedHandlingError(error, recovered: recovered)
//    }
//
//    override func userInteractionNoLongerPermitted(forError error: Error) {
//        super.userInteractionNoLongerPermitted(forError: error)
//    }
//
//    override var hasUnsavedChanges: Bool {
//        return super.hasUnsavedChanges
//    }
}
