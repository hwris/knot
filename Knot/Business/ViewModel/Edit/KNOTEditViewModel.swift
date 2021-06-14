//
//  KNOTEditViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTEditViewModel {
    private let flagColors = [ KNOTFlagColor.blue, .red, .yellow ]
    private var model: KNOTEditModel
    var updateCompleteHandler: ((KNOTEditViewModel) -> Task<Void>)?
    
    init(model: KNOTEditModel) {
        self.model = model
    }
    
    var selectedFlagColorIndex: Int {
        return flagColors.firstIndex(of: KNOTFlagColor(rawValue: model.flagColor) ?? .blue)!
    }
    
    func selectedFlagColor(at index: Int) {
        model.flagColor = flagColors[index].rawValue
    }
    
    func update() -> Task<Void> {
        guard let updateCompleteHandler = self.updateCompleteHandler else {
            return Task(())
        }
        
        let t = updateCompleteHandler(self)
        self.updateCompleteHandler = nil
        return t
    }
}

enum KNOTFlagColor: UInt32 {
    case red = 0xF95943
    case yellow = 0xFFD00E
    case blue = 0x5276FF
}
