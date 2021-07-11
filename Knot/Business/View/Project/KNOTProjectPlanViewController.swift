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
