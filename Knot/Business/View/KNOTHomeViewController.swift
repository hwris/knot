//
//  KNOTHomeViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTHomeViewController: UIViewController {
    
    @IBOutlet var buttons: [KNOTButton]!
    @IBOutlet private weak var addButton: KNOTButton!
    private weak var _tabBarController: UITabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttons.forEach {
            $0.setTitleColor(UIColor(0xFFFFFF, 0.7, 0x070D20, 1.0), for: .normal)
            $0.setTitleColor(UIColor(0xFFFFFF, 0.87, 0x5276FF, 1.0), for: .selected)
            $0.setBackgroundImage(dynamicProvider: {
                let selectedBgColor = $0 == .dark ? UIColor(0xFFFFFF, 0.04) : UIColor(0xF5F6F9, 1.0);
                return UIImage.fromColor(color: selectedBgColor, cornerRadius: 22.0)
            }, for: .selected)
        }
        
        let image = UIImage.fromColor(color: UIColor(0x5276FF), cornerRadius: 28.0)
        addButton.setBackgroundImage(dynamicProvider: {_ in
            return image
        }, for: .normal)
        
        _tabBarController = children.first as? UITabBarController
        _tabBarController.delegate = self
        _tabBarController.selectedIndex = 0;
        buttonDidClicked(buttons[_tabBarController.selectedIndex])
    }
    
    @IBAction func buttonDidClicked(_ sender: KNOTButton) {
        if (sender.isSelected) {
            return
        }
        
        buttons.forEach { $0.isSelected = sender == $0 }
        _tabBarController.selectedIndex = buttons.firstIndex(of: sender)!
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

extension KNOTHomeViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        buttonDidClicked(buttons[_tabBarController.selectedIndex])
    }
}
