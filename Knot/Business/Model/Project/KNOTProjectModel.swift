//
//  KNOTProjectModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/6.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTProjectModel {
    var projectsSubject: Subject<ArraySubscription<KNOTProjectEntity>> { get }
    func loadProjects() -> Task<Void>
    func add(plan: KNOTPlanEntity, toProject project: KNOTProjectEntity) -> Task<Void>
    func updateProject(_ proj: KNOTProjectEntity) -> Task<Void>
    func deleteProject(_ proj: KNOTProjectEntity) -> Task<Void>
    func detailModel(with proj: KNOTProjectEntity) -> KNOTProjectDetailModel
}
