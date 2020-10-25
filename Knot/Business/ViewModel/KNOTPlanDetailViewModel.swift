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
        model.plan.items?.insert(item, at: index)
        let itemVM = KNOTPlanDetailItemViewModel(model: item)
        items.insert(itemVM, at: index)
    }
    
    func updatePlan() throws -> Task<Void> {
        return try model.updatePlan()
    }
}

class KNOTPlanDetailItemViewModel {
    private let model: KNOTPlanItemEntity
    
    init(model: KNOTPlanItemEntity) {
        self.model = model
    }
    
    var content: String {
        return model.content
    }
    
    var isDoneButtonSelected: Bool {
        return model.isDone
    }
    
    func updateContent(_ content: String) {
        model.content = content
    }
    
    func updateIsDone(_ isDone: Bool) {
        model.isDone = isDone
    }
}
