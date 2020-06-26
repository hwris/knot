//
//  KNOTPlanModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/19.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTPlanUpdateModel {
    func updatePlan(_ plan: KNOTPlanEntity) throws -> Task<Void>
}

protocol KNOTPlanModel: KNOTPlanUpdateModel {
    var plansSubject: Subject<[KNOTPlanEntity]> { get }
    func loadPlans() throws -> Task<Void>
    func deletePlan(_ plan: KNOTPlanEntity) throws -> Task<Void>
    func emptyPlanDetailModel(at index: Int) -> KNOTPlanDetailModel
    func planDetailModel(at index: Int) -> KNOTPlanDetailModel
}
