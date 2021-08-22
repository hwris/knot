//
//  KNOTProjectDetailViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTProjectDetailViewModel: KNOTEditViewModel {
    private let model: KNOTProjectDetailModel
    
    override init(model: KNOTEditModel) {
        self.model = model as! KNOTProjectDetailModel
        super.init(model: model)
    }
    
    var projName: String {
        return model.project.name
    }
    
    func updateProjName(_ name: String) {
        model.project.name = name
    }
    
    override func update() -> Task<Void> {
        model.updateProject()
    }
}

class KNOTProjectMoreViewModel: KNOTEditViewModel {
    private let model: KNOTProjectMoreModel
    
    override init(model: KNOTEditModel) {
        self.model = model as! KNOTProjectMoreModel
        super.init(model: model)
    }
    
    override func update() -> Task<Void> {
        return Task(())
    }
    
    func deleteProj() -> Task<Void> {
        model.deleteProject()
    }
}
