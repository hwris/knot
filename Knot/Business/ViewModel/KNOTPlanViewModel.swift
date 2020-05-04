//
//  KNOTPlanViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/5.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTPlanViewModel {
    private let model: KNOTPlanModel
    private var plansSubscription: Subscription<[KNOTDocument<KNOTPlanEntity>]>?
    
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
    
    private func publishPlans(_ plans: [KNOTDocument<KNOTPlanEntity>]?) {
        let items = plans?.filter({
            let calendar = Calendar.current
            let creationDateComponents = calendar.dateComponents([ .day ], from: $0.creationDate)
            let selectedDateComponents = calendar.dateComponents([ .day ], from: self.selectedDate)
            return creationDateComponents.day == selectedDateComponents.day
        }).sorted(by: { $0.contentPriority < $1.contentPriority }).map({ KNOTPlanItemViewModel(model: $0) })
        
        itemsSubject.publish(items)
    }
    
    func loadItems(at date: Date, completion: @escaping (Error?) -> ()) throws {
        guard let plans = model.plansSubject.value else {
            selectedDate = date
            try model.loadItems(completion: completion)
            return
        }
        
        publishPlans(plans)
    }
}

class KNOTPlanItemViewModel {
    private let model: KNOTDocument<KNOTPlanEntity>
    private var contentSubscription: Subscription<KNOTPlanEntity>?
    
    let itemSubject = Subject<Item>()
    
    init(model: KNOTDocument<KNOTPlanEntity>) {
        self.model = model
        contentSubscription = model.contentSubject.listen({ [weak self]  (new, old) in
            self?.publishContent(new)
        })
    }
    
    deinit {
        contentSubscription?.cancel()
        contentSubscription = nil
    }
    
    private func publishContent(_ plan: KNOTPlanEntity?) {
        let item = plan.map({ Item(contentText: $0.content, flagColor: $0.flagColor, alarm: plan?.remindTime != nil) })
        itemSubject.publish(item)
    }
    
    func loadContent() {
        guard let plan = model.contentSubject.value else {
            try? model.loadContent { assert($0) }
            return;
        }
        
        publishContent(plan)
    }
    
    struct Item {
        enum FlagColor: UInt32 {
            case blue = 0x5276FF
            case red = 0xF95943
            case yellow = 0xFFD00E
            
            static func flagBkColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
                switch rawValue {
                case FlagColor.red.rawValue:
                    return (UIColor(0xFEE6E3), UIColor(0x262949))
                case FlagColor.blue.rawValue:
                    return (UIColor(0x5276FF), UIColor(0x262949))
                case FlagColor.yellow.rawValue:
                    return (UIColor(0xFFD00E), UIColor(0x262949))
                default:
                    return (UIColor(rawValue, 0.5), UIColor(0x262949))
                }
            }
            
            static func alarmColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
                switch rawValue {
                case FlagColor.red.rawValue:
                    return (UIColor(0xFB9F93), UIColor(0x262949))
                case FlagColor.blue.rawValue:
                    return (UIColor(0x95A7EB), UIColor(0x262949))
                case FlagColor.yellow.rawValue:
                    return (UIColor(0xFFE374), UIColor(0x262949))
                default:
                    return (UIColor(rawValue, 0.8), UIColor(0x262949))
                }
            }
        }
        
        let contentText: String
        let flagColors: (UIColor, UIColor)
        let flagBkColors: (UIColor, UIColor)
        let alarmColors: (UIColor, UIColor)?
        
        init(contentText: String, flagColor: UInt32, alarm: Bool) {
            self.contentText = contentText
            flagColors = (UIColor(flagColor), UIColor(flagColor))
            flagBkColors = FlagColor.flagBkColors(byRawValue: flagColor)
            alarmColors = alarm ? FlagColor.alarmColors(byRawValue: flagColor) : nil
        }
    }
}
