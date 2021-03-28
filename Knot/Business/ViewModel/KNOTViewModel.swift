//
//  KNOTItemsViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/19.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

class KNOTViewModel {
    private let model: KNOTModel
    
    private(set) lazy var planViewModel = KNOTPlanViewModel(model: self.model.planModel)
    
    init(model: KNOTModel) {
        self.model = model
    }
}

extension KNOTViewModel {
    static func defaultInstance() -> KNOTViewModel {
        return KNOTViewModel(model: KNOTModelDefaultImpl())
    }
}
