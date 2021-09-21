//
//  KNOTProjectPlanViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/7/4.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTProjectPlanViewController: KNOTDragAddViewController {
    var viewModel: KNOTProjectPlanViewModel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = viewModel.title
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? KNOTPlanViewController {
            vc.viewModel = viewModel
        }
    }
}

class KNOTProjectPlanMoreViewController: KNOTPlanMoreViewController {
    private let syncToPlanSegudId = "syncToPlan"
    
    private var isSyncToPlanSwitchOnSubscription: Subscription<Bool>?
    
    @IBOutlet weak var syncToPlanSwitch: UISwitch?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSyncToPlanSwitchOnSubscription = (viewModel as! KNOTProjectPlanMoreViewModel).isSyncToPlanSwitchOnSubject.listen({ [weak self] new, old in
            self?.syncToPlanSwitch?.isOn = new ?? false
        })
    }
    
    @IBAction func syncToPlanSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
            (viewModel as! KNOTProjectPlanMoreViewModel).closeSyncToPlan()
            return
        }
        
        performSegue(withIdentifier: syncToPlanSegudId, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == syncToPlanSegudId {
            hideView()
            let VC = segue.destination as! KNOTProjectPlanPickerViewController
            VC.completion = showView
            VC.viewModel = (viewModel as! KNOTProjectPlanMoreViewModel).syncToPlanViewModel
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

class KNOTProjectPlanPickerViewController: KNOTDialogViewController {
    var viewModel: KNOTProjectSyncToPlanViewModel!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = viewModel.selectedDate
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
    }
    
    override func cancelButtonClicked(_ sender: UIButton) {
        super.cancelButtonClicked(sender)
        viewModel.cancelButtonDidClicked()
    }
    
    override func confirmButtonClicked(_ sender: UIButton) {
        super.confirmButtonClicked(sender)
        viewModel.confirmButtonDidClicked()
        dismiss(animated: true, completion: nil)
    }
}
