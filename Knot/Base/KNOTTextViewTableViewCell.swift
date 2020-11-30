//
//  KNOTTextViewTableViewCell.swift
//  Knot
//
//  Created by 苏杨 on 2020/6/26.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

extension UITableViewCell {
    var tableView: UITableView? {
        var tableView = superview
        while tableView != nil && !(tableView is UITableView) {
            tableView = tableView?.superview
        }
        
        return tableView as? UITableView
    }
    
    func updateTableView() {
        UIView.setAnimationsEnabled(false)
        tableView?.beginUpdates()
        tableView?.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}

class KNOTTextViewTableViewCell: UITableViewCell {
    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.isScrollEnabled = false
            contentTextView.delegate = self
        }
    }
    
    weak var delegate: KNOTTextViewTableViewCellDelegate?
}

extension KNOTTextViewTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        if size.height != newSize.height {
            updateTableView()
        }
        
        delegate?.textViewTableViewCellTextDidChanged(self)
    }
}

protocol KNOTTextViewTableViewCellDelegate: AnyObject {
    func textViewTableViewCellTextDidChanged(_ cell: KNOTTextViewTableViewCell)
}
