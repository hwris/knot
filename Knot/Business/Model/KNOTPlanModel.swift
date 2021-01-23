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
    func loadPlans() throws -> Task<Void>
    func updatePlan(_ plan: KNOTPlanEntity) throws -> Task<Void>
    func deletePlan(_ plan: KNOTPlanEntity) throws -> Task<Void>
    func insertPlan(at index: Int) throws -> KNOTPlanDetailModel
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel
}
