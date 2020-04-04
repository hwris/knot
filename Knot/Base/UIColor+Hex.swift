//
//  UIColor+Hex.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(_ rgb: UInt32, _ alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((rgb & 0xff0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0x00ff00) >> 8) / 255.0,
                  blue: CGFloat((rgb & 0x0000ff)) / 255.0,
                  alpha: alpha)
    }
}
