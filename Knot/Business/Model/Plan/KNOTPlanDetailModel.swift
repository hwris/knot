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
}

protocol KNOTPlanMoreModel: KNOTEditModel {
    var plan: KNOTPlanEntity { get }
    var syncToProjModel: KNOTPlanSyncToProjModel { get }
}

protocol KNOTPlanSyncToProjModel {
    var projs: [KNOTProjectEntity] { get }
    func syncPlanTo(_ proj: KNOTProjectEntity) -> Task<Void>
}
