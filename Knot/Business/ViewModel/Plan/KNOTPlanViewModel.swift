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
        vm.planDidDone = { [unowned self] in
            return self.model.updatePlan($0.model)
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
                                  flagColor: KNOTFlagColor.blue.rawValue)
        let detailModel = model.planDetailModel(with: plan)
        let detailViewModel = KNOTPlanDetailViewModel(model: detailModel)
        detailViewModel.updateCompleteHandler = { [weak self] _ in
            return self?.updatePlan(at: index, insert: plan) ?? Task(())
        }
        return detailViewModel
    }
    
    func planDetailViewModel(at index: Int) -> KNOTPlanDetailViewModel {
        let plan = itemsSubject.value!.0![index].model
        let detailViewModel = KNOTPlanDetailViewModel(model: model.planDetailModel(with: plan))
        detailViewModel.updateCompleteHandler = { [weak self] _ in
            return self?.updatePlan(at: index, insert: nil) ?? Task(())
        }
        return detailViewModel
    }
    
    func moreViewModel(at index: Int) -> KNOTPlanMoreViewModel {
        let plan = itemsSubject.value!.0![index].model
        let moreViewModel = KNOTPlanMoreViewModel(model: model.planMoreModel(with: plan))
        moreViewModel.updateCompleteHandler = { [weak self] _ in
            return (self?.updatePlan(at: index, insert: nil) ?? Task(()))
        }
        moreViewModel.deletePlanFunc = { [weak self] _ in
            guard let s = self else {
                return Task(())
            }
            
            let t = s.model.deletePlan(plan)
            return t.continueWith(.mainThread, continuation: { t in
                if let e = t.error {
                    throw e
                }
                
                var planViewModels = s.itemsSubject.value?.0 ?? []
                planViewModels.remove(at: index)
                s.itemsSubject.publish((planViewModels, .remove, [IndexPath(row: index, section: 0)]))
            })
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
    class ItemColors {
        let flagColors: (UIColor, UIColor)
        let flagBkColors: (UIColor, UIColor)
        let flagImageName: String
        let alarmColors: (UIColor, UIColor)?
        
        init(flagColor: UInt32, alarm: Bool) {
            flagColors = (UIColor(flagColor), UIColor(flagColor))
            flagBkColors = ItemColors.flagBkColors(byRawValue: flagColor)
            flagImageName = ItemColors.flagImageName(byRawValue: flagColor)
            alarmColors = alarm ? ItemColors.alarmColors(byRawValue: flagColor) : nil
        }
        
        private class func flagBkColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return (UIColor(0xFEE6E3), UIColor(0x262949))
            case KNOTFlagColor.blue.rawValue:
                return (UIColor(0xE5EBFF), UIColor(0x262949))
            case KNOTFlagColor.yellow.rawValue:
                return (UIColor(0xFFF6CF), UIColor(0x262949))
            default:
                return (UIColor(rawValue, 0.5), UIColor(0x262949))
            }
        }

        private class func alarmColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return (UIColor(0xFB9F93), UIColor(0x262949))
            case KNOTFlagColor.blue.rawValue:
                return (UIColor(0x95A7EB), UIColor(0x262949))
            case KNOTFlagColor.yellow.rawValue:
                return (UIColor(0xFFE374), UIColor(0x262949))
            default:
                return (UIColor(rawValue, 0.8), UIColor(0x262949))
            }
        }

        private class func flagImageName(byRawValue rawValue: UInt32) -> String {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return "ic_select_on_red"
            case KNOTFlagColor.blue.rawValue:
                return "ic_select_on_blue"
            case KNOTFlagColor.yellow.rawValue:
                return "ic_select_on_yellow"
            default:
                return "ic_select_on_blue"
            }
        }
    }
    
    fileprivate let model: KNOTPlanEntity
    fileprivate var planDidDone: ((KNOTPlanItemViewModel) -> Task<Void>)?
    
    private(set) var content: String!
    var isDone: Bool { return model.isDone }
    private(set) var items: [KNOTPlanItemItemViewModel]!
    private(set) var colors: ItemColors!
    let shoudldAlarm = Subject(value: false)
    var cachedContent: Any?
    
    init(model: KNOTPlanEntity) {
        self.model = model
        refresh()
    }
    
    fileprivate func refresh(shoudldAlarm: Bool = false) {
        content = model.content
        items = model.items?.map({ KNOTPlanItemItemViewModel(model: $0) }) ?? []
        colors = ItemColors(flagColor: model.flagColor, alarm: model.remindTime != nil)
        cachedContent = nil
        self.shoudldAlarm.publish(shoudldAlarm)
    }
    
    func makePlanDone(_ isDone: Bool) -> Task<Void> {
        let old = model.isDone
        model.isDone = isDone
        return planDidDone?(self) ?? Task(()).continueOnErrorWith {_ in 
            self.model.isDone = old
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
