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
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func syncToPlanSwitchChanged(_ sender: UISwitch) {
        sender.isOn = false
        performSegue(withIdentifier: syncToPlanSegudId, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == syncToPlanSegudId {
            hideView()
            let VC = segue.destination as! KNOTProjectPlanPickerViewController
            VC.completion = showView
            VC.viewModel = viewModel.syncToPlanViewModel
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
    
    override func confirmButtonClicked(_ sender: UIButton) {
        super.confirmButtonClicked(sender)
        viewModel.confirmButtonDidClicked()
        dismiss(animated: true, completion: nil)
    }
}
