//
//  KNOTPickerView.swift
//  Knot
//
//  Created by 苏杨 on 2021/4/4.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTPickerView: UIPickerView {
    override func didAddSubview(_ subview: UIView) {
        // hide selection indicator
        subview.backgroundColor = .clear
        super.didAddSubview(subview)
    }
}
