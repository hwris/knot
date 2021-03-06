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
    var itemsSubject = Subject<CollectionSubscription<[KNOTPlanItemViewModel]>>()
    
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
        let calendar = Calendar.current
        let selectedDateComponents = calendar.dateComponents([ .year, .month, .day ], from: self.selectedDate)
        let items = plans?.filter({
            let creationDateComponents = calendar.dateComponents([ .year, .month, .day ], from: $0.remindDate)
            return creationDateComponents == selectedDateComponents
        }).sorted(by: { $0.priority > $1.priority }).map({ KNOTPlanItemViewModel(model: $0) })
        
        itemsSubject.publish((items, .reset))
    }
    
    func loadItems(at date: Date) -> Task<Void> {
        guard let plans = model.plansSubject.value else {
            selectedDate = date
            return model.loadPlans()
        }
        
        guard selectedDate != date else {
            return Task(())
        }
        
        selectedDate = date
        publishPlans(plans.0)
        return Task(())
    }
    
    func insertPlan(at index: Int) -> KNOTPlanDetailViewModel {
        var highPriority = Double.greatestFiniteMagnitude
        var lowPriority = Double.leastNormalMagnitude
        if let planViewModels = itemsSubject.value?.0 {
            if index < planViewModels.endIndex {
                highPriority = planViewModels[index].model.priority
            }
            
            if index - 1 >= planViewModels.startIndex {
                lowPriority = planViewModels[index - 1].model.priority
            }
        }
        let plan = KNOTPlanEntity(remindDate: selectedDate,
                                  priority: (highPriority + lowPriority) * 0.5,
                                  content: "",
                                  flagColor: KNOTPlanItemFlagColor.blue.rawValue)
        let detailModel = model.planDetailModel(with: plan)
        let detailViewModel = KNOTPlanDetailViewModel(model: detailModel)
        return detailViewModel
    }
    
    func updatePlan(at index: Int, insert detailViewModel: KNOTPlanDetailViewModel? = nil) -> Task<Void> {
        var planViewModels = itemsSubject.value?.0 ?? []
        var itemViewModel: KNOTPlanItemViewModel!
        if let plan = detailViewModel?.model.plan {
            itemViewModel = KNOTPlanItemViewModel(model: plan)
            planViewModels.insert(itemViewModel, at: index)
            itemsSubject.publish((planViewModels, .insert))
        } else {
            itemViewModel = planViewModels[index]
            itemViewModel.refresh()
            itemsSubject.publish((planViewModels, .update))
        }
        return model.updatePlan(itemViewModel.model)
    }
    
//    func makeDonePlan(at index: Int) {
//        let plan = itemsSubject.value!.0![index].model
//    }
    
    func planDetailViewModel(at index: Int) -> KNOTPlanDetailViewModel {
        let plan = itemsSubject.value!.0![index].model
        return KNOTPlanDetailViewModel(model: model.planDetailModel(with: plan))
    }
}

class KNOTPlanItemViewModel {
    fileprivate let model: KNOTPlanEntity
    
    private(set) var content: String
    private(set) var items: [KNOTPlanItemItemViewModel]
    private(set) var colors: ItemColors
    var cachedContent: Any?
    
    init(model: KNOTPlanEntity) {
        content = model.content
        items = model.items?.map({ KNOTPlanItemItemViewModel(model: $0) }) ?? []
        colors = ItemColors(flagColor: model.flagColor, alarm: model.remindTime != nil)
        self.model = model
    }
    
    fileprivate func refresh() {
        content = model.content
        items = model.items?.map({ KNOTPlanItemItemViewModel(model: $0) }) ?? []
        colors = ItemColors(flagColor: model.flagColor, alarm: model.remindTime != nil)
        cachedContent = nil
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
