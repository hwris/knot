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
    
    func loadEntity(completion: (Error) -> ())
    func save(completion: (Error) -> ())
}

class KNOTProjectItemModelImpl : KNOTProjectItemModel {
    let fileURL: URL
    
    private(set) var projectEntity: KNOTProjectEntity?
    
    init(fileURL: URL, projectEntity: KNOTProjectEntity? = nil) {
        self.fileURL = fileURL
        self.projectEntity = projectEntity
    }
    
    func loadEntity(completion: (Error) -> ()) {
    }
    
    func save(completion: (Error) -> ()) {
    }
}
