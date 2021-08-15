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
    func updateProject(_ proj: KNOTProjectEntity) -> Task<Void>
    func deleteProject(_ proj: KNOTProjectEntity) -> Task<Void>
    func projectDetailModel(with proj: KNOTProjectEntity) -> KNOTProjectDetailModel
    func projectPlansModel(with proj: KNOTProjectEntity) -> KNOTPlanModel
    func projectMoreModel(with proj: KNOTProjectEntity) -> KNOTProjectMoreModel
}
