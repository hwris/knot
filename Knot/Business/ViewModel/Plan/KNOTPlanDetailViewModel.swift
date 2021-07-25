//
//  KNOTPlanDetailViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/25.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTPlanDetailViewModel: KNOTEditViewModel {
    private let model: KNOTPlanDetailModel
    private(set) var items: [KNOTPlanDetailItemViewModel]
    
    override init(model: KNOTEditModel) {
        self.model = model as! KNOTPlanDetailModel
        items = self.model.plan.items?.map({ KNOTPlanDetailItemViewModel(model: $0) }) ?? []
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

class KNOTPlanMoreViewModel: KNOTEditViewModel {
    let model: KNOTPlanMoreModel
    var deletePlanFunc: ((KNOTPlanMoreViewModel) -> Task<Void>)?
    let isRepeatSwitchOnSubject: Subject<Bool>
    let isReminderSwitchOnSubject: Subject<Bool>
    
    override init(model: KNOTEditModel) {
        self.model = model as! KNOTPlanMoreModel
        isRepeatSwitchOnSubject = Subject(value: self.model.plan.repeat != nil)
        isReminderSwitchOnSubject = Subject(value: self.model.plan.remindTime != nil)
        super.init(model: model)
    }
    
    func closeRepeat() {
        model.plan.repeat = nil
        isRepeatSwitchOnSubject.publish(false)
    }
    
    var repeatViewModel: KNOTPickerViewModel {
        let vm = KNOTPlanRepeatViewModel(model: model.plan)
        vm.isRepeatSwitchOnSubject = isRepeatSwitchOnSubject
        return vm
    }
    
    func closeReminder() {
        model.plan.remindTime = nil
        isReminderSwitchOnSubject.publish(false)
    }
    
    var reminderViewModel: KNOTPickerViewModel {
        let vm = KNOTPlanReminderViewModel(model: model.plan)
        vm.isReminderSwitchOnSubject = isReminderSwitchOnSubject
        return vm
    }
    
    var syncToProjViewModel: KNOTPickerViewModel {
        return KNOTPlanSyncToProjViewModel(model: model.syncToProjModel)
    }
    
    func deletePlan() -> Task<Void> {
        return deletePlanFunc?(self) ?? Task(())
    }
}

private class KNOTPlanRepeatViewModel: KNOTPickerViewModel {
    private let intervalIndex = 0
    private let typeIndex = 1
    
    private let model: KNOTPlanEntity
    fileprivate var isRepeatSwitchOnSubject: Subject<Bool>?
    private var selectedIntervalIndex = 0
    private var selectedTypeIndex = 0
    
    init(model: KNOTPlanEntity) {
        self.model = model
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
        switch component {
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
        case intervalIndex:
            return 60
        case typeIndex:
            return 160
        default:
            return 0
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

private class KNOTPlanReminderViewModel: KNOTPickerViewModel {
    private let timePeriodIndex = 0
    private let hourIndex = 1
    private let minuteIndex = 2
    
    private let model: KNOTPlanEntity
    fileprivate var isReminderSwitchOnSubject: Subject<Bool>?
    private var selectedTimePeriodIndex = 0
    private var selectedHourIndex = 0
    private var selectedMinuteIndex = 0
    
    init(model: KNOTPlanEntity) {
        self.model = model
    }
    
    var numberOfComponents: Int {
        return 3
    }
    
    func numberOfRows(inComponent component: Int) -> Int {
        switch component {
        case timePeriodIndex:
            return 2
        case hourIndex:
            return 12
        case minuteIndex:
            return 60
        default:
            return 0
        }
    }
    
    func title(forRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case timePeriodIndex:
            return row == 0 ? NSLocalizedString("AM", comment: "") : NSLocalizedString("PM", comment: "")
        case hourIndex:
            return "\(row + 1)"
        case minuteIndex:
            return row <= 9 ? "0\(row)" : "\(row)"
        default:
            return ""
        }
    }
    
    func width(forComponent component: Int) -> CGFloat {
        return 110
    }
    
    func didSelect(row: Int, inComponent component: Int) {
        switch component {
        case timePeriodIndex:
            selectedTimePeriodIndex = row
        case hourIndex:
            selectedHourIndex = row
        case minuteIndex:
            selectedMinuteIndex = row
        default:
            break
        }
    }
    
    func confirmButtonDidClicked() {
        let sampleHour = selectedHourIndex + 1
        let hour = selectedTimePeriodIndex == 0 ? sampleHour : sampleHour + 12
        let dateComponents = DateComponents(calendar: .current, timeZone: .current, hour: hour, minute: selectedMinuteIndex)
        model.remindTime = dateComponents.date!
        isReminderSwitchOnSubject?.publish(true)
    }
}

private class KNOTPlanSyncToProjViewModel: KNOTPickerViewModel {
    private let model: KNOTPlanSyncToProjModel
    private var selectedProjIndex = 0
    
    init(model: KNOTPlanSyncToProjModel) {
        self.model = model
    }
    
    var numberOfComponents: Int {
        return 1
    }
    
    func numberOfRows(inComponent component: Int) -> Int {
        return model.projs.count
    }
    
    func title(forRow row: Int, forComponent component: Int) -> String? {
        return model.projs[row].name
    }
    
    func width(forComponent component: Int) -> CGFloat {
        return 330
    }
    
    func didSelect(row: Int, inComponent component: Int) {
        selectedProjIndex = row
    }
    
    func confirmButtonDidClicked() {
        let proj = model.projs[selectedProjIndex]
        model.syncPlanTo(proj).continueOnErrorWith { e in
            // handle error
            assert(false, e.localizedDescription)
        }
    }
}

