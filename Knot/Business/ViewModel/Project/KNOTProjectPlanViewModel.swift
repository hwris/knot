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
    let isSyncToPlanSwitchOnSubject: Subject<Bool>
    
    override init(model: KNOTEditModel) {
        isSyncToPlanSwitchOnSubject = Subject(value: false)
        super.init(model: model)
    }
    
    var syncToPlanViewModel: KNOTProjectSyncToPlanViewModel {
        let model = (model as! KNOTProjectPlanMoreModel).syncToPlanModel
        let vm = KNOTProjectSyncToPlanViewModel(model: model)
        vm.isSyncToPlanSwitchOnSubject = isSyncToPlanSwitchOnSubject
        return vm
    }
    
    func closeSyncToPlan() {
        syncToPlanViewModel.closeSyncToPlan()
    }
}

class KNOTProjectSyncToPlanViewModel {
    private let model: KNOTProjectSyncToPlanModel
    fileprivate var isSyncToPlanSwitchOnSubject: Subject<Bool>?
    var selectedDate = Date()
    
    init(model: KNOTProjectSyncToPlanModel) {
        self.model = model
        selectedDate = model.plan.remindDate ?? Date()
    }
    
    func confirmButtonDidClicked() {
        model.plan.remindDate = selectedDate
        isSyncToPlanSwitchOnSubject?.publish(true)
    }
    
    func cancelButtonDidClicked() {
        isSyncToPlanSwitchOnSubject?.publish(false)
    }
    
    func closeSyncToPlan() {
        model.plan.remindDate = nil
        isSyncToPlanSwitchOnSubject?.publish(false)
    }
}
