//
//  KNOTSearchModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/8/8.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import Foundation

protocol KNOTSearchModel {
    func search(with text: String) -> ([KNOTPlanEntity], [KNOTProjectEntity]);
    func planDetailModel(with plan: KNOTPlanEntity) -> KNOTPlanDetailModel
    func projectDetailModel(with proj: KNOTProjectEntity) -> KNOTProjectDetailModel
}
