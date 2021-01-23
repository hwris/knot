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
    private var plansSubscription: Subscription<CollectionSubscription<[KNOTPlanEntity]>>?
    
    private var selectedDate = Date()
    let itemsSubject = Subject<[KNOTPlanItemViewModel]>()
    
    init(model: KNOTPlanModel) {
        self.model = model
        plansSubscription = model.plansSubject.listen({ [weak self] (newValue, _) in
            guard let (plans, action) = newValue, action == .reset else {
                return
            }
            
            self?.publishPlans(plans)
        })
    }
    
    deinit {
        plansSubscription?.cancel()
        plansSubscription = nil
    }
    
    private func publishPlans(_ plans: [KNOTPlanEntity]?) {
        let items = plans?.filter({
            let calendar = Calendar.current
            let creationDateComponents = calendar.dateComponents([ .year, .month, .day ], from: $0.creationDate)
            let selectedDateComponents = calendar.dateComponents([ .year, .month, .day ], from: self.selectedDate)
            return creationDateComponents == selectedDateComponents
        }).sorted(by: { $0.priority < $1.priority }).map({ KNOTPlanItemViewModel(model: $0) })
        
        itemsSubject.publish(items)
    }
    
    func loadItems(at date: Date) throws -> Task<Void> {
        guard let plans = model.plansSubject.value else {
            selectedDate = date
            return try model.loadPlans()
        }
        
        guard selectedDate != date else {
            return Task(())
        }
        
        selectedDate = date
        publishPlans(plans.0)
        return Task(())
    }
    
    func insertPlan(at index: Int) throws -> KNOTPlanDetailViewModel {
        return try KNOTPlanDetailViewModel(model: model.insertPlan(at: index))
    }
    
    func updatePlan(at index: Int) throws -> Task<Void> {
        let plan = itemsSubject.value![index].model
        return try model.updatePlan(plan)
    }
    
    func makeDonePlan(at index: Int) {
        let plan = itemsSubject.value![index].model
    }
    
    func planDetailViewModel(at index: Int) -> KNOTPlanDetailViewModel {
        let plan = itemsSubject.value![index].model
        return KNOTPlanDetailViewModel(model: model.planDetailModel(with: plan))
    }
}

class KNOTPlanItemViewModel {
    fileprivate let model: KNOTPlanEntity
    
    let content: String
    let items: [KNOTPlanItemItemViewModel]
    let colors: ItemColors
    
    var cachedContent: Any?
    
    init(model: KNOTPlanEntity) {
        content = model.content
        items = model.items?.map({ KNOTPlanItemItemViewModel(model: $0) }) ?? []
        colors = ItemColors(flagColor: model.flagColor, alarm: model.remindTime != nil)
        self.model = model
    }

    struct ItemColors {
        let flagColors: (UIColor, UIColor)
        let flagBkColors: (UIColor, UIColor)
        let flagImageName: String
        let alarmColors: (UIColor, UIColor)?
        
        init(flagColor: UInt32, alarm: Bool) {
            flagColors = (UIColor(flagColor), UIColor(flagColor))
            flagBkColors = KNOTPlanItemFlagColor.flagBkColors(byRawValue: flagColor)
            flagImageName = KNOTPlanItemFlagColor.flagImageName(byRawValue: flagColor)
            alarmColors = alarm ? KNOTPlanItemFlagColor.alarmColors(byRawValue: flagColor) : nil
        }
    }
}

class KNOTPlanItemItemViewModel {
    let model: KNOTPlanItemEntity
    
    init(model: KNOTPlanItemEntity) {
        self.model = model
    }
    
    var content: String {
        return model.content
    }
    
    var isDoneButtonSelected: Bool {
        return model.isDone
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
    
    static func flagImageName(byRawValue rawValue: UInt32) -> String {
        switch rawValue {
        case KNOTPlanItemFlagColor.red.rawValue:
            return "ic_select_on_red"
        case KNOTPlanItemFlagColor.blue.rawValue:
            return "ic_select_on_blue"
        case KNOTPlanItemFlagColor.yellow.rawValue:
            return "ic_select_on_yellow"
        default:
            return "ic_select_on_blue"
        }
    }
}
