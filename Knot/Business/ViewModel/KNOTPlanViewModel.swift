//
//  KNOTPlanViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/5.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit
import BoltsSwift

class KNOTPlanViewModel {
    private let model: KNOTPlanModel
    private var plansSubscription: Subscription<[KNOTPlanEntity]>?
    
    private var selectedDate = Date()
    let itemsSubject = Subject<[KNOTPlanItemViewModel]>()
    
    init(model: KNOTPlanModel) {
        self.model = model
        plansSubscription = model.plansSubject.listen({ [weak self] (newValue, _) in
            self?.publishPlans(newValue)
        })
    }
    
    deinit {
        plansSubscription?.cancel()
        plansSubscription = nil
    }
    
    private func publishPlans(_ plans: [KNOTPlanEntity]?) {
        let items = plans?.filter({
            let calendar = Calendar.current
            let creationDateComponents = calendar.dateComponents([ .day ], from: $0.creationDate)
            let selectedDateComponents = calendar.dateComponents([ .day ], from: self.selectedDate)
            return creationDateComponents.day == selectedDateComponents.day
        }).sorted(by: { $0.priority < $1.priority }).map({ KNOTPlanItemViewModel(model: $0) })
        
        itemsSubject.publish(items)
    }
    
    func loadItems(at date: Date) throws -> Task<Void> {
        guard let plans = model.plansSubject.value else {
            selectedDate = date
            return try model.loadPlans()
        }
        
        publishPlans(plans)
        return Task(())
    }
    
    func insertPlan(at index: Int) throws -> KNOTPlanDetailViewModel {
        return try KNOTPlanDetailViewModel(model: model.insertPlan(at: index))
    }
    
    func planDetailViewModel(at index: Int) -> KNOTPlanDetailViewModel {
        return KNOTPlanDetailViewModel(model: model.planDetailModel(at: index))
    }
}

class KNOTPlanItemViewModel {
    private let model: KNOTPlanEntity
    
    private(set) var item: Item
    
    init(model: KNOTPlanEntity) {
        self.model = model
        item = Item(contentText: model.content, flagColor: model.flagColor, alarm: model.remindTime != nil)
    }

    struct Item {
        let contentText: String
        let flagColors: (UIColor, UIColor)
        let flagBkColors: (UIColor, UIColor)
        let alarmColors: (UIColor, UIColor)?
        
        init(contentText: String, flagColor: UInt32, alarm: Bool) {
            self.contentText = contentText
            flagColors = (UIColor(flagColor), UIColor(flagColor))
            flagBkColors = KNOTPlanItemFlagColor.flagBkColors(byRawValue: flagColor)
            alarmColors = alarm ? KNOTPlanItemFlagColor.alarmColors(byRawValue: flagColor) : nil
        }
    }
}

enum KNOTPlanItemFlagColor: UInt32 {
    case blue = 0x5276FF
    case red = 0xF95943
    case yellow = 0xFFD00E
    
    static func flagBkColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
        switch rawValue {
        case KNOTPlanItemFlagColor.red.rawValue:
            return (UIColor(0xFEE6E3), UIColor(0x262949))
        case KNOTPlanItemFlagColor.blue.rawValue:
            return (UIColor(0xE5EBFF), UIColor(0x262949))
        case KNOTPlanItemFlagColor.yellow.rawValue:
            return (UIColor(0xFFF6CF), UIColor(0x262949))
        default:
            return (UIColor(rawValue, 0.5), UIColor(0x262949))
        }
    }
    
    static func alarmColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
        switch rawValue {
        case KNOTPlanItemFlagColor.red.rawValue:
            return (UIColor(0xFB9F93), UIColor(0x262949))
        case KNOTPlanItemFlagColor.blue.rawValue:
            return (UIColor(0x95A7EB), UIColor(0x262949))
        case KNOTPlanItemFlagColor.yellow.rawValue:
            return (UIColor(0xFFE374), UIColor(0x262949))
        default:
            return (UIColor(rawValue, 0.8), UIColor(0x262949))
        }
    }
}
