//
//  KNOTProjectPlanModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/7/25.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTProjectPlanMoreModel: KNOTPlanMoreModel {
    var syncToPlanModel: KNOTProjectSyncToPlanModel { get }
}

protocol KNOTProjectSyncToPlanModel {
    var plan: KNOTPlanEntity { get }
}
