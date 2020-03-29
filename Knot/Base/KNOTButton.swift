//
//  KNOTButton.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTButton: UIButton {
    private var backgroundImageDynamicProvider: (UIControl.State, (KNOTUserInterfaceStyle) -> UIImage?)?
    
    func setBackgroundImage(dynamicProvider: @escaping (KNOTUserInterfaceStyle) -> UIImage?, for state: UIControl.State) {
        if #available(iOS 12.0, *) {
            setBackgroundImage(dynamicProvider(KNOTUserInterfaceStyle(rawValue: traitCollection.userInterfaceStyle.rawValue) ?? .unspecified), for: state)
        } else {
            setBackgroundImage(dynamicProvider(.unspecified), for: state)
        }
        
        backgroundImageDynamicProvider = (state, dynamicProvider)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let _backgroundImageDynamicProvider = backgroundImageDynamicProvider {
                    setBackgroundImage(dynamicProvider: _backgroundImageDynamicProvider.1, for: _backgroundImageDynamicProvider.0)
                }
            }
        }
    }
}
