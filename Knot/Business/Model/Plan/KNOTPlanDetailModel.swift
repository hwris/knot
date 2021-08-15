//
//  KNOTPlanDetailModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/6/6.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTPlanDetailModel: KNOTEditModel {
    var plan: KNOTPlanEntity { get }
    func updatePlan() -> Task<Void>
}

protocol KNOTPlanMoreModel: KNOTPlanDetailModel {
    var syncToProjModel: KNOTPlanSyncToProjModel { get }
    func deletePlan() -> Task<Void>
}

protocol KNOTPlanSyncToProjModel {
    var projs: [KNOTProjectEntity] { get }
    func syncPlanTo(_ proj: KNOTProjectEntity) -> Task<Void>
}
