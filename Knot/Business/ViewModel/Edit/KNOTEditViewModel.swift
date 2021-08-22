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
    
    init(model: KNOTEditModel) {
        self.model = model
    }
    
    var selectedFlagColorIndex: Int {
        return flagColors.firstIndex(of: KNOTFlagColor(rawValue: model.flagColor) ?? .blue)!
    }
    
    var needUpdate: Bool {
        model.needUpdate
    }
    
    func selectedFlagColor(at index: Int) {
        model.flagColor = flagColors[index].rawValue
    }
    
    func update() -> Task<Void> {
        fatalError("Should implement by subclass")
    }
}

enum KNOTFlagColor: UInt32 {
    case red = 0xF95943
    case yellow = 0xFFD00E
    case blue = 0x5276FF
}
