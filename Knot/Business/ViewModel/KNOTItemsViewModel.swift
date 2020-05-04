//
//  KNOTItemsViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/19.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

class KNOTViewModel {
    private let model: KNOTPlanModel
    private var plansSubscription: Subscription<[KNOTDocument<KNOTPlanEntity>]>?
    
    private var selectedDate = Date()
    private(set) var items: [KNOTPlanItemViewModel]?
    
    init(model: KNOTPlanModel) {
        self.model = model
        plansSubscription = model.plansSubject.listen({ [weak self] (newValue, _) in
            guard let ss = self else {
                return
            }
            
            ss.items = newValue?.filter({
                let calendar = Calendar.current
                let creationDateComponents = calendar.dateComponents([ .day ], from: $0.creationDate)
                let selectedDateComponents = calendar.dateComponents([ .day ], from: ss.selectedDate)
                return creationDateComponents.day == selectedDateComponents.day
            }).sorted(by: { $0.contentPriority < $1.contentPriority }).map({ KNOTPlanItemViewModel(model: $0) })
        })
    }
    
    func loadItems(at date: Date, completion: ((Error?) -> ())?) {
        
    }
}

class KNOTItemViewModel<T: Codable> {
    let model: KNOTDocument<T>
    
    init(model: KNOTDocument<T>) {
        self.model = model
    }
}
