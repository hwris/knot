//
//  KNOTHomeViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTHomeViewController: UIViewController {
    @IBOutlet private var buttons: [KNOTButton]!
    @IBOutlet private weak var addButton: KNOTHomeAddButton!
    fileprivate var snapshotAddButton: UIView?
    private weak var _tabBarController: UITabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttons.forEach {
            $0.setTitleColor(UIColor(0xFFFFFF, 0.7, 0x070D20, 1.0), for: .normal)
            $0.setTitleColor(UIColor(0xFFFFFF, 0.87, 0x5276FF, 1.0), for: .selected)
            
            let darkImage = UIImage.fromColor(color: UIColor(0xFFFFFF, 0.04), cornerRadius: 22.0)
            let lightImage = UIImage.fromColor(color: UIColor(0xF5F6F9, 1.0), cornerRadius: 22.0)
            $0.setBackgroundImage(dynamicProvider: {
                return $0 == .dark ? darkImage : lightImage
            }, for: .selected)
        }
        
        let addImage = UIImage.fromColor(color: UIColor(0x5276FF), cornerRadius: 28.0)
        let deleteLightImage = UIImage.fromColor(color: UIColor(0x545865), cornerRadius: 28.0)
        let deleteDarkImage = UIImage.fromColor(color: UIColor(0xffffff, 0.12), cornerRadius: 28.0)
        addButton.setBackgroundImage(dynamicProvider: {_ in
            return addImage;
        }, for: .normal)
        addButton.setBackgroundImage(dynamicProvider: {
            return $0 == .dark ? deleteDarkImage : deleteLightImage;
        }, for: .selected)
        addButton.delegate = self
        
        _tabBarController = children.first as? UITabBarController
        _tabBarController.selectedIndex = 0;
        buttonDidClicked(buttons[_tabBarController.selectedIndex])
    }
    
    fileprivate var selectedItemViewController: UIViewController & KNOTHomeItemViewController {
        return _tabBarController.selectedViewController as! UIViewController & KNOTHomeItemViewController
    }
    
    @IBAction func buttonDidClicked(_ sender: KNOTButton) {
        if (sender.isSelected) {
            return
        }
        
        buttons.forEach { $0.isSelected = sender == $0 }
        _tabBarController.selectedIndex = buttons.firstIndex(of: sender)!
    }
}

extension KNOTHomeViewController: KNOTHomeAddButtonDelegate {
    func addButton(_ button: KNOTHomeAddButton, beginTracking touch: UITouch, with event: UIEvent?) {
        if let snapshotAddButton = button.snapshotView(afterScreenUpdates: false) {
            snapshotAddButton.alpha = 0
            self.snapshotAddButton = snapshotAddButton
            view.addSubview(snapshotAddButton)
        }
        
        button.isSelected = true
        
        if #available(iOS 10.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        selectedItemViewController.homeViewController(self, addButton: button, continueTracking: touch)
    }
    
    func addButton(_ button: KNOTHomeAddButton, continueTracking touch: UITouch, with event: UIEvent?) {
        let inButton = button.bounds.contains(touch.location(in: button))
        snapshotAddButton?.alpha = inButton ? 0 : 1.0
        snapshotAddButton?.center = touch.location(in: view)
        
        selectedItemViewController.homeViewController(self, addButton: button, continueTracking: touch)
    }
    
    func addButton(_ button: KNOTHomeAddButton, endTracking touch: UITouch?, with event: UIEvent?) {
        snapshotAddButton?.removeFromSuperview()
        snapshotAddButton = nil
        
        button.isSelected = false
        
        var isEndInAddbutton = false
        if let p = touch?.location(in: button), button.bounds.contains(p) {
            isEndInAddbutton = true
        }
        
        selectedItemViewController.homeViewController(self,
                                                      addButton: addButton,
                                                      endTracking:touch,
                                                      inAddButton: isEndInAddbutton)
    }
    
    func addButton(_ button: KNOTHomeAddButton, cancelTrackingWith event: UIEvent?) {
        addButton(button, endTracking: nil, with: event)
    }
}

protocol KNOTHomeItemViewController {
    func homeViewController(_ homeViewController: KNOTHomeViewController,
                            addButton button: UIButton,
                            continueTracking touch: UITouch)
    func homeViewController(_ homeViewController: KNOTHomeViewController,
                            addButton button: UIButton,
                            endTracking touch: UITouch?,
                            inAddButton: Bool)
}

class KNOTHomeAddButton: KNOTButton {
    weak var delegate: (AnyObject & KNOTHomeAddButtonDelegate)?
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let r = super.beginTracking(touch, with: event)
        if r {
            delegate?.addButton(self, beginTracking: touch, with: event)
        }
        return r
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let r = super.continueTracking(touch, with: event)
        if r {
            delegate?.addButton(self, continueTracking: touch, with: event)
        }
        return r;
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        delegate?.addButton(self, endTracking: touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        delegate?.addButton(self, cancelTrackingWith: event)
    }
}

protocol KNOTHomeAddButtonDelegate {
    func addButton(_ button: KNOTHomeAddButton, beginTracking touch: UITouch, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, continueTracking touch: UITouch, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, endTracking touch: UITouch?, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, cancelTrackingWith event: UIEvent?)
}
