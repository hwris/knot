//
//  KNOTProjectDetailModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTProjectDetailModel: KNOTEditModel {
    var project: KNOTProjectEntity { get }
}
