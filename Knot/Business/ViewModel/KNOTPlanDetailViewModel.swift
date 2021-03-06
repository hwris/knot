//
//  KNOTPlanDetailViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/25.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTPlanDetailViewModel {
    private let model: KNOTPlanDetailModel
    private(set) var items: [KNOTPlanDetailItemViewModel]
    var didUpdatePlan: ((KNOTPlanDetailViewModel) -> Task<Void>)?
    
    init(model: KNOTPlanDetailModel) {
        self.model = model
        items = model.plan.items?.map({ KNOTPlanDetailItemViewModel(model: $0) }) ?? []
    }
    
    var content: String {
        return model.plan.content
    }
    
    let flagColorS = [ KNOTPlanItemFlagColor.blue, .red, .yellow ]
    
    var selectedFlagColorIndex: Int {
        return flagColorS.firstIndex(of: KNOTPlanItemFlagColor(rawValue: model.plan.flagColor) ?? .blue)!
    }
    
    func updateContent(_ content: String) {
        model.plan.content = content
    }
    
    func selectedFlagColor(at index: Int) {
        model.plan.flagColor = flagColorS[index].rawValue
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
    
    func updatePlan() -> Task<Void> {
        guard let didUpdatePlan = self.didUpdatePlan else {
            return Task(())
        }
        
        let t = didUpdatePlan(self)
        self.didUpdatePlan = nil
        return t
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
