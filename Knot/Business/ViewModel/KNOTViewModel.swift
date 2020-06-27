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
    
    private var _planViewModel: KNOTPlanViewModel!
    
    init(model: KNOTModel) {
        self.model = model
    }
    
    var planViewModel: KNOTPlanViewModel {
        if _planViewModel == nil {
            _planViewModel = KNOTPlanViewModel(model: self.model.planModel)
        }
        
        return _planViewModel
    }
}
