//
//  KNOTPlanDetailViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/25.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTPlanEditViewModel {
    private let flagColorS = [ KNOTPlanItemFlagColor.blue, .red, .yellow ]
    private let model: KNOTPlanEditModel
    var updateCompleteHandler: ((KNOTPlanEditViewModel) -> Task<Void>)?
    
    init(model: KNOTPlanEditModel) {
        self.model = model
    }
    
    var selectedFlagColorIndex: Int {
        return flagColorS.firstIndex(of: KNOTPlanItemFlagColor(rawValue: model.plan.flagColor) ?? .blue)!
    }
    
    func selectedFlagColor(at index: Int) {
        model.plan.flagColor = flagColorS[index].rawValue
    }
    
    func updatePlan() -> Task<Void> {
        guard let updateCompleteHandler = self.updateCompleteHandler else {
            return Task(())
        }
        
        let t = updateCompleteHandler(self)
        self.updateCompleteHandler = nil
        return t
    }
}

class KNOTPlanDetailViewModel: KNOTPlanEditViewModel{
    private let model: KNOTPlanDetailModel
    private(set) var items: [KNOTPlanDetailItemViewModel]
    
    override init(model: KNOTPlanEditModel) {
        self.model = model as! KNOTPlanDetailModel
        items = model.plan.items?.map({ KNOTPlanDetailItemViewModel(model: $0) }) ?? []
        super.init(model: model)
    }
    
    var content: String {
        return model.plan.content
    }
    
    func updateContent(_ content: String) {
        model.plan.content = content
    }
    
    func insertItem(at index: Int) {
        let item = KNOTPlanItemEntity(content: "")
        if model.plan.items == nil { model.plan.items = [] }
        model.plan.items?.insert(item, at: index)
        
        let itemVM = KNOTPlanDetailItemViewModel(model: item)
        items.insert(itemVM, at: index)
    }
    
    func moveItem(at srcIndex: Int, to dstIndex: Int) {
        if srcIndex == dstIndex {
            return
        }
        
        let tempPlanItem = model.plan.items![srcIndex]
        model.plan.items![srcIndex] = model.plan.items![dstIndex]
        model.plan.items![dstIndex] = tempPlanItem
        
        let tempPlanItemVM = items[srcIndex]
        items[srcIndex] = items[dstIndex]
        items[dstIndex] = tempPlanItemVM
    }
}

class KNOTPlanDetailItemViewModel: KNOTPlanItemItemViewModel {
    func updateContent(_ content: String) {
        model.content = content
    }
    
    func updateIsDone(_ isDone: Bool) {
        model.isDone = isDone
    }
}

class KNOTPlanMoreViewModel: KNOTPlanEditViewModel {
    private let model: KNOTPlanMoreModel
    
    override init(model: KNOTPlanEditModel) {
        self.model = model as! KNOTPlanMoreModel
        super.init(model: model)
    }
    
    var isRepeatSwitchOn: Bool {
        return model.plan.repeat != nil
    }
    
    func closeRepeat() {
        model.plan.repeat = nil
    }
    
    var repeatViewModel: KNOTPlanRepeatViewModel {
        return KNOTPlanRepeatViewModel(model: model.plan)
    }
}

class KNOTPlanRepeatViewModel {
    private let model: KNOTPlanEntity
    private var selectedIntervalIndex: Int = 0
    private var selectedTypeIndex: Int = 0
    
    init(model: KNOTPlanEntity) {
        self.model = model
        if let repeat_ = model.repeat {
            selectedIntervalIndex = repeat_.interval - 1
            selectedTypeIndex = repeat_.type.rawValue
        }
    }
    
    private var numberOfIntervalRows: Int {
        return 100
    }
    
    private func intervalTitle(at index: Int) -> String {
        return "\(index + 1)"
    }
    
    private var numberOfTypeRows: Int {
        return KNOTPlanEntity.Repeat.Type_.allCases.count
    }
    
    private func typeTitle(at index: Int) -> String {
        guard let type = KNOTPlanEntity.Repeat.Type_(rawValue: index) else {
            return ""
        }
        
        switch type {
        case .Day:
            return NSLocalizedString("Day(s)", comment: "")
        case .Week:
            return NSLocalizedString("Week(s)", comment: "")
        case .Month:
            return NSLocalizedString("Month(s)", comment: "")
        case .Year:
            return NSLocalizedString("Year(s)", comment: "")
        }
    }
    
    var numberOfComponents: Int {
        return 2
    }
    
    func numberOfRows(inComponent component: Int) -> Int {
        return component == 0 ? numberOfIntervalRows : numberOfTypeRows
    }
    
    func title(forRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? intervalTitle(at: row) : typeTitle(at: row)
    }
    
    func didSelect(row: Int, inComponent component: Int) {
        if component == 0 {
            selectedIntervalIndex = row
        } else {
            selectedTypeIndex = row
        }
    }
    
    func confirmButtonDidClicked() {
        guard let type = KNOTPlanEntity.Repeat.Type_(rawValue: selectedTypeIndex) else {
            return
        }
        let repeat_ = KNOTPlanEntity.Repeat(interval: selectedIntervalIndex + 1, type: type)
        model.repeat = repeat_
    }
}

