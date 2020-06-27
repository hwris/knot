//
//  KNOTPlanDetailViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/24.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTPlanDetailViewController: UIViewController {
    fileprivate let titleRowIndex = 0
    
    var viewModel: KNOTPlanDetailViewModel!
    
    @IBOutlet weak var keyboardButton: UIButton!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet var flagButtons: [UIButton]!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var actionViewBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardButton.isHidden = true
        flagColorButtonCliked(flagButtons[viewModel.selectedFlagColorIndex])
        
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
    
    @IBAction func flagColorButtonCliked(_ sender: UIButton) {
        if sender.isSelected {
            return
        }
        
        sender.isSelected = true
        flagButtons.forEach { $0.isSelected = $0 == sender }
        
        if let index = flagButtons.firstIndex(of: sender), index != viewModel.selectedFlagColorIndex {
            viewModel.selectedFlagColor(at: index)
        }
    }
    
    @IBAction func listButtonCliked(_ sender: UIButton) {
    }
    
    @IBAction func bkViewTapped(_ sender: UITapGestureRecognizer) {
        let _ = try? viewModel.updatePlan()
        dismiss(animated: true, completion: nil)
    }
}

extension KNOTPlanDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items?.count ?? 0 + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isTitle = indexPath.row == titleRowIndex
        let cellId = isTitle ? "titleCell" : "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! KNOTTextViewTableViewCell
        if (isTitle) {
            let textView = cell.contentTextView!
            textView.text = viewModel.content
            if textView.text.isEmpty {
                textView.becomeFirstResponder()
            }
        } else {
            (cell as! KNOTPlanDetaiListCell).viewModel = viewModel.items![indexPath.row - 1]
        }
        cell.delegate = self
        return cell
    }
}

extension KNOTPlanDetailViewController: KNOTTextViewTableViewCellDelegate {
    func textViewTableViewCellTextDidChanged(_ cell: KNOTTextViewTableViewCell) {
        guard let indexPath = itemsTableView.indexPath(for: cell) else {
            return
        }
        
        if indexPath.row == titleRowIndex {
            viewModel.updateContent(cell.contentTextView.text)
        }
    }
}

class KNOTPlanDetaiListCell: KNOTTextViewTableViewCell {
    @IBOutlet weak var isDoneButtong: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    
    var viewModel: KNOTPlanDetailItemViewModel! {
        didSet {
            contentTextView.text = viewModel.content
            isDoneButtong.isSelected = viewModel.isDoneButtonSelected
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        viewModel.updateContent(textView.text)
    }
    
    @IBAction func doneButtonCliked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        viewModel.updateIsDone(sender.isSelected)
    }
}


