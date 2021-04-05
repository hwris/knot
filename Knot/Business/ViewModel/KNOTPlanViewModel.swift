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
    private var plansSubscription: Subscription<ArraySubscription<KNOTPlanEntity>>?
    private var selectedDate = Date()
    let itemsSubject = Subject<ArrayIndexPathSubscription<KNOTPlanItemViewModel>>()
    
    init(model: KNOTPlanModel) {
        self.model = model
        plansSubscription = model.plansSubject.listen({ [weak self] (newValue, _) in
            guard let (plans, action, _) = newValue, action == .reset else {
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
        let items = model.plans(onDay: selectedDate)
            .sorted(by: { $0.priority > $1.priority })
            .map({ planItemViewModel(model: $0) })
        itemsSubject.publish((items, .reset, nil))
    }
    
    private func planItemViewModel(model: KNOTPlanEntity) -> KNOTPlanItemViewModel {
        let vm = KNOTPlanItemViewModel(model: model)
        vm.planDidDone = { [unowned self] (planItemViewModel) in
            guard var planItemViewModels = self.itemsSubject.value?.0,
                  let index = (planItemViewModels.firstIndex { $0 === planItemViewModel }) else {
                return Task(())
            }
            
            return self.model.updatePlan(planItemViewModel.model).continueOnSuccessWith(.mainThread) {
                planItemViewModels.remove(at: index)
                self.itemsSubject.publish((planItemViewModels, .remove, [IndexPath(row: index, section: 0)]))
            }
        }
        return vm
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
                lowPriority = planViewModels[index].model.priority
            }
            
            if index - 1 >= planViewModels.startIndex {
                highPriority = planViewModels[index - 1].model.priority
            }
        }
        let plan = KNOTPlanEntity(remindDate: selectedDate,
                                  priority: (highPriority + lowPriority) * 0.5,
                                  content: "",
                                  flagColor: KNOTPlanItemFlagColor.blue.rawValue)
        let detailModel = model.planDetailModel(with: plan)
        let detailViewModel = KNOTPlanDetailViewModel(model: detailModel)
        detailViewModel.updateCompleteHandler = { [weak self] _ in
            return (self?.updatePlan(at: index, insert: plan) ?? Task(()))
        }
        return detailViewModel
    }
    
    func planDetailViewModel(at index: Int) -> KNOTPlanDetailViewModel {
        let plan = itemsSubject.value!.0![index].model
        let detailViewModel = KNOTPlanDetailViewModel(model: model.planDetailModel(with: plan))
        detailViewModel.updateCompleteHandler = { [weak self] _ in
            return (self?.updatePlan(at: index, insert: nil) ?? Task(()))
        }
        return detailViewModel
    }
    
    func moreViewModel(at index: Int) -> KNOTPlanMoreViewModel {
        let plan = itemsSubject.value!.0![index].model
        let moreViewModel = KNOTPlanMoreViewModel(model: model.planMoreModel(with: plan))
        moreViewModel.updateCompleteHandler = { [weak self] _ in
            return (self?.updatePlan(at: index, insert: nil) ?? Task(()))
        }
        return moreViewModel
    }
    
    private func updatePlan(at index: Int, insert _plan: KNOTPlanEntity? = nil) -> Task<Void> {
        var planViewModels = itemsSubject.value?.0 ?? []
        var itemViewModel: KNOTPlanItemViewModel!
        if let plan = _plan {
            itemViewModel = planItemViewModel(model: plan)
            planViewModels.insert(itemViewModel, at: index)
            itemsSubject.publish((planViewModels, .insert, [IndexPath(row: index, section: 0)]))
        } else {
            itemViewModel = planViewModels[index]
            itemViewModel.refresh()
            itemsSubject.publish((planViewModels, .update, [IndexPath(row: index, section: 0)]))
        }
        return model.updatePlan(itemViewModel.model)
    }
}

class KNOTPlanItemViewModel {
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
    
    fileprivate let model: KNOTPlanEntity
    fileprivate var planDidDone: ((KNOTPlanItemViewModel) -> Task<Void>)?
    
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
    
    func makePlanDone() -> Task<Void> {
        model.isDone = true
        return planDidDone?(self) ?? Task(())
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
