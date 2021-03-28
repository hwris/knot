//
//  KNOTPlanDetailModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/6/6.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

protocol KNOTPlanEditModel {
    var plan: KNOTPlanEntity { get }
}

protocol KNOTPlanDetailModel: KNOTPlanEditModel {
}

protocol KNOTPlanMoreModel: KNOTPlanEditModel {
}
