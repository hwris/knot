//
//  KNOTPlanModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/19.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

protocol KNOTPlanModel {
    var plansSubject: Subject<[KNOTDocument<KNOTPlanEntity>]> { get }
    func loadItems(completion: @escaping (Error?) -> ()) throws
}
