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
    
    init(model: KNOTModel) {
        self.model = model
    }
    
    var planViewModel: KNOTPlanViewModel {
        return KNOTPlanViewModel(model: model.planModel)
    }
    
    var projectViewModel: KNOTProjectViewModel {
        return KNOTProjectViewModel(model: model.projectModel)
    }
    
    var searchViewModel: KNOTSearchViewModel {
        return KNOTSearchViewModel(model: model.searchModel)
    }
}

extension KNOTViewModel {
    static func defaultInstance() -> KNOTViewModel {
        return KNOTViewModel(model: KNOTModelDefaultImpl())
    }
}
