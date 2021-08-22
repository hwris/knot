//
//  KNOTEditViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTEditViewController<VieModel: KNOTEditViewModel>: KNOTTranslucentViewController {
    var viewModel: VieModel!
    
    @IBOutlet weak var keyboardButton: UIButton?
    @IBOutlet weak var actionViewBottom: NSLayoutConstraint?
    @IBOutlet var flagButtons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardButton?.isHidden = true
        flagColorButtonCliked(flagButtons.filter({ $0.tag == viewModel.selectedFlagColorIndex }).first!)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidChangeFrame(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    override func handleBackgroundViewTapped(completion: @escaping () -> ()) {
        if !viewModel.needUpdate {
            completion()
            dismiss(animated: true, completion: nil)
            return
        }
        
        viewModel.update().continueWith(.mainThread) {
            if let error = $0.error {
                assert(false, error.localizedDescription)
                // Todo: handle error
                completion()
                return
            }
            completion()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func flagColorButtonCliked(_ sender: UIButton) {
        if sender.isSelected {
            return
        }
        
        sender.isSelected = true
        flagButtons.forEach { $0.isSelected = $0 == sender }
        
        if sender.tag != viewModel.selectedFlagColorIndex {
            viewModel.selectedFlagColor(at: sender.tag)
        }
    }
    
    @objc @IBAction func keyboardDidChangeFrame(_ not: Notification) {
        guard let frame = (not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
        let keyboardAnimationDuration = not.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        guard let actionViewBottom = self.actionViewBottom, let keyboardButton = self.keyboardButton else {
            return
        }

        actionViewBottom.constant = keyboardButton.isHidden ? 0 : frame.height
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc @IBAction func keyboardWillShow(_ not: Notification) {
        keyboardButton?.isHidden = false
        keyboardDidChangeFrame(not)
    }
    
    @objc @IBAction func keyboardWillHide(_ not: Notification) {
        keyboardButton?.isHidden = true
        keyboardDidChangeFrame(not)
    }
    
    @IBAction func keyboardClicked(_ sender: UIButton) {
        view.endEditing(true)
    }
}
