//
//  KNOTHomeViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTHomeViewController: UIViewController {
    
    @IBOutlet weak var planButton: KNOTButton!
    @IBOutlet weak var projectButton: KNOTButton!
    @IBOutlet weak var addButton: KNOTButton!
    @IBOutlet weak var tabBarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let normalTitleColor = UIColor { $0 == .dark ? UIColor(hex: 0xFFFFFF, alpha: 0.7) : UIColor(hex: 0x070D20)}
        let selectedTitleColor = UIColor { $0 == .dark ? UIColor(hex: 0xFFFFFF, alpha: 0.87) : UIColor(hex: 0x5276FF)}
        let selectedBgImage = { (style: KNOTUserInterfaceStyle) -> UIImage? in
            let selectedBgColor = UIColor { $0 == .dark ? UIColor(hex: 0xFFFFFF, alpha: 0.04) : UIColor(hex: 0xF5F6F9)}
            return UIImage.fromColor(color: selectedBgColor, cornerRadius: 22.0)
        }
        let addButtonBgImage = { (style: KNOTUserInterfaceStyle) -> UIImage? in
            return UIImage.fromColor(color: UIColor(hex: 0x5276FF), cornerRadius: 28.0)
        }
        
        view.backgroundColor = UIColor { $0 == .dark ? UIColor(hex: 0x070D20) : UIColor(hex: 0xf2f2f2) }
        planButton.setTitleColor(normalTitleColor, for: .normal)
        planButton.setTitleColor(selectedTitleColor, for: .selected)
        planButton.setBackgroundImage(dynamicProvider: selectedBgImage, for: .selected)
        projectButton.setTitleColor(normalTitleColor, for: .normal)
        projectButton.setTitleColor(selectedTitleColor, for: .selected)
        projectButton.setBackgroundImage(dynamicProvider: selectedBgImage, for: .selected)
        addButton.setBackgroundImage(dynamicProvider: addButtonBgImage, for: .normal)
        tabBarView.backgroundColor = UIColor { $0 == .dark ? UIColor(hex: 0x070D20) : UIColor.white }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
