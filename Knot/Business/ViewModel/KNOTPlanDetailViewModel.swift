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
    let isRepeatSwitchOnSubject: Subject<Bool>
    
    override init(model: KNOTPlanEditModel) {
        self.model = model as! KNOTPlanMoreModel
        isRepeatSwitchOnSubject = Subject(value: model.plan.repeat != nil)
        super.init(model: model)
    }
    
    func closeRepeat() {
        model.plan.repeat = nil
        isRepeatSwitchOnSubject.publish(false)
    }
    
    var repeatViewModel: KNOTPlanRepeatViewModel {
        let vm = KNOTPlanRepeatViewModel(model: model.plan)
        vm.isRepeatSwitchOnSubject = isRepeatSwitchOnSubject
        return vm
    }
}

class KNOTPlanRepeatViewModel {
    private let everyIndex = 0
    private let intervalIndex = 1
    private let typeIndex = 2
    
    private let model: KNOTPlanEntity
    fileprivate var isRepeatSwitchOnSubject: Subject<Bool>?
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
        return 3
    }
    
    func numberOfRows(inComponent component: Int) -> Int {
        switch component {
        case everyIndex:
            return 1
        case intervalIndex:
            return numberOfIntervalRows
        case typeIndex:
            return numberOfTypeRows
        default:
            return 0
        }
    }
    
    func title(forRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case everyIndex:
            return NSLocalizedString("Every", comment: "")
        case intervalIndex:
            return intervalTitle(at: row)
        case typeIndex:
            return typeTitle(at: row)
        default:
            return ""
        }
    }
    
    func width(forComponent component: Int) -> CGFloat {
        switch component {
        case everyIndex:
            return 110
        case intervalIndex:
            return 60
        default:
            return 160
        }
    }
    
    func didSelect(row: Int, inComponent component: Int) {
        switch component {
        case intervalIndex:
            selectedIntervalIndex = row
        case typeIndex:
            selectedTypeIndex = row
        default:
            break
        }
    }
    
    func confirmButtonDidClicked() {
        guard let type = KNOTPlanEntity.Repeat.Type_(rawValue: selectedTypeIndex) else {
            return
        }
        let repeat_ = KNOTPlanEntity.Repeat(interval: selectedIntervalIndex + 1, type: type)
        model.repeat = repeat_
        isRepeatSwitchOnSubject?.publish(true)
    }
}

