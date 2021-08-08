//
//  KNOTSearchViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/8/8.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTSearchViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var searchViewLeading: NSLayoutConstraint!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitleColor(UIColor(0xFFFFFF, 0.87, 0x070D20, 1.0), for: .normal)
        searchTextField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonClicked(_ sender: UIButton) {
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
    }
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension KNOTSearchViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}
