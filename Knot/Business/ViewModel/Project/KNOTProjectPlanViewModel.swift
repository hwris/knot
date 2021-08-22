//
//  KNOTProjectPlanViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/7/25.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTProjectPlanViewModel: KNOTPlanViewModel {
    var title: String?
    
    override func moreViewModel(at index: Int) -> KNOTPlanMoreViewModel {
        let mode = super.moreViewModel(at: index).model
        return KNOTProjectPlanMoreViewModel(model: mode)
    }
}

class KNOTProjectPlanMoreViewModel: KNOTPlanMoreViewModel {
    var syncToPlanViewModel: KNOTProjectSyncToPlanViewModel {
        let model = (model as! KNOTProjectPlanMoreModel).syncToPlanModel
        return KNOTProjectSyncToPlanViewModel(model: model)
    }
}

class KNOTProjectSyncToPlanViewModel {
    private let model: KNOTProjectSyncToPlanModel
    var selectedDate = Date()
    
    init(model: KNOTProjectSyncToPlanModel) {
        self.model = model
        selectedDate = model.plan.remindDate ?? Date()
    }
    
    func confirmButtonDidClicked() {
        model.syncToDate(selectedDate).continueOnErrorWith { e in
            // handle error
            assert(false, e.localizedDescription)
        }
    }
}
