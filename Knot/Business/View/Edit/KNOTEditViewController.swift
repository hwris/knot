//
//  KNOTEditViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit
import BoltsSwift

class KNOTEditViewController<VieModel: KNOTEditViewModel>: KNOTTranslucentViewController {
    private var keyboardAnimationTask: Task<Void>?
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
    
    deinit {
        removeNotificationObservers()
    }
    
    private func removeNotificationObservers() {
        let names = [ UIResponder.keyboardDidChangeFrameNotification,
                      UIResponder.keyboardWillShowNotification,
                      UIResponder.keyboardWillHideNotification]
        names.forEach {
            NotificationCenter.default.removeObserver(self,
                                                      name: $0,
                                                      object: nil)
        }
    }
    
    override func handleBackgroundViewTapped(completion: @escaping () -> ()) {
        removeNotificationObservers()
        
        let updateTask = {
            self.viewModel.update().continueWith(.mainThread) {
                if let error = $0.error {
                    assert(false, error.localizedDescription)
                    // Todo: handle error
                    completion()
                    return
                }
                completion()
                self.dismiss(animated: true)
            }
        }
        
        if keyboardAnimationTask == nil {
            let _ = updateTask()
            return
        }
        
        keyboardAnimationTask?.continueWith(continuation: { _ in
            let _ = updateTask()
        })
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

        let constant = keyboardButton.isHidden ? 0 : frame.height
        if actionViewBottom.constant == constant {
            return
        }
        
        let tcs = TaskCompletionSource<Void>()
        keyboardAnimationTask = tcs.task
        actionViewBottom.constant = constant
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        } completion: { _ in
            tcs.set(result: ())
            self.keyboardAnimationTask = nil
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
