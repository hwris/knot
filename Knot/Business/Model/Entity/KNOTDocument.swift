//
//  KNOTDocument.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/28.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit
import BoltsSwift

class KNOTDocument<T: Codable> {
    let fileURL: URL
    private var doc: KNOTDocumentInternal<T>!
    fileprivate(set) var content: T?
   
    init(fileURL: URL) {
        self.fileURL = fileURL
        doc = KNOTDocumentInternal(docInfo: self)
    }
    
    deinit {
        doc.close()
    }
    
    func loadContent() -> Task<Bool> {
        let tcs = TaskCompletionSource<Bool>()
        doc.open() { tcs.set(result: $0) }
        return tcs.task
    }
    
    func save(content: T) -> Task<Bool> {
        let tcs = TaskCompletionSource<Bool>()
        if !doc.isOpening {
            loadContent().continueWith { (t) -> Bool in
                tcs.set(result: t.result!)
                return t.result!
            }
        } else {
            tcs.set(result: true)
        }
        
        return tcs.task.continueOnSuccessWith { (t) -> Bool in
            self.content = content
            self.doc.updateChangeCount(.done)
            return true
        }
    }
}
     
private class KNOTDocumentInternal<T: Codable>: UIDocument {
    private weak var docInfo: KNOTDocument<T>?
    private(set) var isOpening = false
    
    init(docInfo: KNOTDocument<T>) {
        self.docInfo = docInfo
        super.init(fileURL: docInfo.fileURL)
    }
    
    override func open(completionHandler: ((Bool) -> Void)? = nil) {
        super.open {
            self.isOpening = $0
            completionHandler?($0)
        }
    }
    
    override func close(completionHandler: ((Bool) -> Void)? = nil) {
        isOpening = false
        super.close()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw NSError(domain: "KNOTDocumentLoadErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey : "Data is invalid" ])
        }
        docInfo?.content = try JSONDecoder().decode(T.self, from: data)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let content = docInfo?.content else {
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
