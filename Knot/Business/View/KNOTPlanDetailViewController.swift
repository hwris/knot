//
//  KNOTPlanDetailViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/24.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTPlanDetailViewController: UIViewController {
    
    var viewModel: KNOTPlanDetailViewModel!
    
    @IBOutlet weak var keyboardButton: UIButton!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet var flagButtons: [UIButton]!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var actionViewBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        keyboardButton.isHidden = true
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
    
    @IBAction func bkViewTapped(_ sender: UITapGestureRecognizer) {
        let _ = try? viewModel.updatePlan()
        dismiss(animated: true, completion: nil)
    }
    
    @objc @IBAction func keyboardDidChangeFrame(_ not: Notification) {
        guard let frame = (not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
        let keyboardAnimationDuration = not.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        actionViewBottom.constant = keyboardButton.isHidden ? 0 : frame.height
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc @IBAction func keyboardWillShow(_ not: Notification) {
        keyboardButton.isHidden = false
        keyboardDidChangeFrame(not)
    }
    
    @objc @IBAction func keyboardWillHide(_ not: Notification) {
        keyboardButton.isHidden = true
        keyboardDidChangeFrame(not)
    }
    
    @IBAction func keyboardClicked(_ sender: UIButton) {
        view.endEditing(true)
    }
}

extension KNOTPlanDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = indexPath.row == 0 ? "titleCell" : "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! KNOTPlanDetaiListCell
        cell.contentTextView.text = "test"
        return cell
    }
}

class KNOTPlanDetaiListCell: KNOTTextViewTableViewCell {
    
}
