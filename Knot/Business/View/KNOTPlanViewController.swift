//
//  KNOTPlanViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/4.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTPlanViewController: KNOTHomeItemTableViewController {
    private var itemsSubscription: Subscription<[KNOTPlanItemViewModel]>?
    
    var viewModel: KNOTPlanViewModel! {
        didSet {
            itemsSubscription?.cancel()
            itemsSubscription = viewModel.itemsSubject.listen({ [weak self] (_, _) in
                self?.tableView.reloadData()
            })
            
            //todo: error handle
            do {
                try viewModel.loadItems(at: Date()) { (error) in
                    assert(error == nil)
                }
            } catch let e  {
                print(e)
            }
        }
    }
    
    deinit {
        itemsSubscription?.cancel()
        itemsSubscription = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var numberOfDateRows: Int {
        return viewModel?.itemsSubject.value?.count ?? 0;
    }
    
    override func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        let itemCell = cell as! KNOTPlanItemCell
        itemCell.viewModel = (viewModel.itemsSubject.value)![indexPath.row]
    }
}

class KNOTPlanItemCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var flagView: UIView!
    @IBOutlet weak var flagBackgroundView: UIView!
    @IBOutlet weak var alarmBackgroundView: UIImageView!
    @IBOutlet weak var alarmImageView: UIImageView!
    
    private var itemSubscription: Subscription<KNOTPlanItemViewModel.Item>?
    
    var viewModel: KNOTPlanItemViewModel! {
        didSet {
            itemSubscription?.cancel()
            itemSubscription = viewModel.itemSubject.listen({ [weak self] (newValue, _) in
                self?.itemDidUpdated(newValue)
            })
            viewModel.loadContent()
        }
    }
    
    deinit {
        itemSubscription?.cancel()
        itemSubscription = nil
    }
    
    private func itemDidUpdated(_ item: KNOTPlanItemViewModel.Item?) {
        contentLabel.text = item?.contentText
        flagView.backgroundColor = item?.flagColors.0
        flagView.darkBackgroundColor = item?.flagColors.1
        flagBackgroundView.backgroundColor = item?.flagBkColors.0
        flagBackgroundView.darkBackgroundColor = item?.flagBkColors.1
        alarmBackgroundView.isHidden = item?.alarmColors == nil
        alarmImageView.tintColor = item?.alarmColors?.0
        alarmImageView.darkTintColor = item?.alarmColors?.1
    }
    
    @IBAction func moreButtonClicked(_ sender: UIButton) {
    }
}

class KNOTPlanEmptyItemCell: UITableViewCell {
}
