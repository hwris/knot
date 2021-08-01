//
//  KNOTProjectDetailViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/14.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTProjectDetailViewController: KNOTEditViewController<KNOTProjectDetailViewModel> {
    @IBOutlet weak var nameTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextView.text = viewModel.projName
        nameTextView.becomeFirstResponder()
    }
}

extension KNOTProjectDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        if size.height <= newSize.height {
            textView.scrollRectToVisible(CGRect(x: 0, y: newSize.height, width: size.width, height: 0), animated: true)
        }
        viewModel.updateProjName(textView.text)
    }
}

class KNOTProjectMoreViewController: KNOTEditViewController<KNOTProjectMoreViewModel>  {
    var deleteProjFunc: ((KNOTProjectMoreViewController) -> (Void))?
    var renameProjFunc: ((KNOTProjectMoreViewController) -> (Void))?
    var context: Any?
    
    @IBAction func deleteSwitchChanged(_ sender: UISwitch) {
        sender.isEnabled = false
        deleteProjFunc?(self)
    }
    
    @IBAction func renameSwitchChanged(_ sender: UISwitch) {
        sender.isEnabled = false
        renameProjFunc?(self)
    }
}
