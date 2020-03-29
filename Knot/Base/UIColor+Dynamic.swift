//
//  KNOTColorManager.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

public enum KNOTUserInterfaceStyle : Int {
    case unspecified = 0

    case light = 1

    case dark = 2
}

extension UIColor {
    convenience init(dynamicProviderForUserInterfaceStyle: @escaping (KNOTUserInterfaceStyle) -> UIColor) {
        if #available(iOS 13.0, *) {
            self.init(dynamicProvider: { (traitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified:
                    return dynamicProviderForUserInterfaceStyle(.unspecified)
                case .light:
                    return dynamicProviderForUserInterfaceStyle(.light)
                case .dark:
                    return dynamicProviderForUserInterfaceStyle(.dark)
                @unknown default:
                    return dynamicProviderForUserInterfaceStyle(.unspecified)
                }
            })
        } else {
            let color = dynamicProviderForUserInterfaceStyle(.unspecified)
            self.init(cgColor: color.cgColor)
        }
    }
}
