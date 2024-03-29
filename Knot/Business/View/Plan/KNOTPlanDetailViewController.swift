//
//  KNOTPlanDetailViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/5/24.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTPlanDetailViewController: KNOTEditViewController<KNOTPlanDetailViewModel> {
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var listButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.setEditing(true, animated: false)
    }
    
    @IBAction func listButtonCliked(_ sender: UIButton) {
        let index = viewModel.items.count
        viewModel.insertItem(at: index)
        itemsTableView.insertRows(at: [IndexPath(row: index + 1, section: 0)], with: .none)
    }
    
    override var enableHalfScreen: Bool { true }
}

extension KNOTPlanDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.isPlanTitleRow) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! KNOTPlanDetailListTitleCell
            cell.viewModel = viewModel
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! KNOTPlanDetailListCell
            cell.viewModel = viewModel.items[indexPath.planItemRowIndex]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !indexPath.isPlanTitleRow
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return !indexPath.isPlanTitleRow
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        viewModel.moveItem(at: sourceIndexPath.planItemRowIndex, to: destinationIndexPath.planItemRowIndex)
    }
}

extension KNOTPlanDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return proposedDestinationIndexPath.isPlanTitleRow ? sourceIndexPath : proposedDestinationIndexPath
    }
}

class KNOTPlanDetailListTitleCell: KNOTTextViewTableViewCell {
    var viewModel: KNOTPlanDetailViewModel! {
        didSet {
            contentTextView.text = viewModel.content
            
            if viewModel.content.isEmpty {
                contentTextView.becomeFirstResponder()
            }
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        viewModel.updateContent(textView.text)
    }
}

class KNOTPlanDetailListCell: KNOTTextViewTableViewCell {
    @IBOutlet weak var isDoneButtong: UIButton!
    
    var viewModel: KNOTPlanDetailItemViewModel! {
        didSet {
            contentTextView.text = viewModel.content
            isDoneButtong.isSelected = viewModel.isDoneButtonSelected
            contentTextView.alpha = viewModel.isDoneButtonSelected ? 0.5 : 1.0
            
            if viewModel.content.isEmpty {
                contentTextView.becomeFirstResponder()
            }
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        viewModel.updateContent(textView.text)
    }
    
    @IBAction func doneButtonCliked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        contentTextView.alpha = sender.isSelected ? 0.5 : 1.0
        viewModel.updateIsDone(sender.isSelected)
    }
}

class KNOTPlanMoreViewController: KNOTEditViewController<KNOTPlanMoreViewModel>  {
    private let repeatSegueId = "repeat"
    private let reminderSegueId = "reminder"
    private let syncToProjSegudId = "syncToProj"
    
    private var isRepeatSwitchOnSubscription: Subscription<Bool>?
    private var isReminderSwitchOnSubscription: Subscription<Bool>?
    private var isSyncToProjSwitchOnSubscription: Subscription<Bool>?
    
    @IBOutlet weak var repeatSwitch: UISwitch?
    @IBOutlet weak var reminderSwitch: UISwitch?
    @IBOutlet weak var syncToProjSwitch: UISwitch?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isRepeatSwitchOnSubscription = viewModel.isRepeatSwitchOnSubject.listen({ [weak self] (new, old) in
            self?.repeatSwitch?.isOn = new ?? false
        })
        isReminderSwitchOnSubscription = viewModel.isReminderSwitchOnSubject.listen({ [weak self] (new, old) in
            self?.reminderSwitch?.isOn = new ?? false
        })
        isSyncToProjSwitchOnSubscription = viewModel.isSyncToProjSwitchOnSubject.listen({ [weak self] (new, old) in
            self?.syncToProjSwitch?.isOn = new ?? false
        })
    }
    
    deinit {
        isRepeatSwitchOnSubscription?.cancel()
        isRepeatSwitchOnSubscription = nil
        isReminderSwitchOnSubscription?.cancel()
        isReminderSwitchOnSubscription = nil
    }
    
    @IBAction func repeatSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
            viewModel.closeRepeat()
            return
        }
        
        performSegue(withIdentifier: repeatSegueId, sender: nil)
    }
    
    @IBAction func reminderSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
            viewModel.closeReminder()
            return
        }
        
        performSegue(withIdentifier: reminderSegueId, sender: nil)
    }
    
    @IBAction func syncToProjSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
            viewModel.closeSyncToProj()
            return
        }
        
        performSegue(withIdentifier: syncToProjSegudId, sender: nil)
    }
    
    @IBAction func deleteSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
           return
        }
        
        //todo: 加上提示
        viewModel.deletePlan().continueWith { [weak self] t in
            if let e = t.error {
                assert(false, e.localizedDescription)
                //todo: handle error
                return
            }
            
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == repeatSegueId {
            hideView()
            let VC = segue.destination as! KNOTPlanPickerViewController
            VC.completion = showView
            VC.viewModel = viewModel.repeatViewModel
        } else if segue.identifier == reminderSegueId {
            hideView()
            let VC = segue.destination as! KNOTPlanPickerViewController
            VC.completion = showView
            VC.viewModel = viewModel.reminderViewModel
        } else if segue.identifier == syncToProjSegudId {
            hideView()
            let VC = segue.destination as! KNOTPlanPickerViewController
            VC.completion = showView
            VC.viewModel = viewModel.syncToProjViewModel
        }
    }
    
    func hideView() {
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 0
        }
    }
    
    func showView() {
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1.0
        }
    }
}

class KNOTPlanPickerViewController: KNOTPickerViewController {
}

fileprivate extension IndexPath {
    var isPlanTitleRow: Bool {
        return row == 0
    }
    
    var planItemRowIndex: Int {
        return row - 1
    }
}
