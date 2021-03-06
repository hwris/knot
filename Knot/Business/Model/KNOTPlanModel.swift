//
//  KNOTPlanModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/19.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTPlanModel {
    var plansSubject: Subject<CollectionSubscription<[KNOTPlanEntity]>> { get }
    func loadPlans() -> Task<Void>
    func updatePlan(_ plan: KNOTPlanEntity) -> Task<Void>
    func deletePlan(_ plan: KNOTPlanEntity) -> Task<Void>
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel
}
