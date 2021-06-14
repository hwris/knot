//
//  KNOTPlanDetailModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/6/6.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

protocol KNOTPlanDetailModel: KNOTEditModel {
    var plan: KNOTPlanEntity { get }
}

protocol KNOTPlanMoreModel: KNOTEditModel {
    var plan: KNOTPlanEntity { get }
}
