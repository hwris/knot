//
//  KNOTPlanViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/4.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit
import BoltsSwift

class KNOTPlanViewController: KNOTHomeItemTableViewController<KNOTPlanViewModel> {
    fileprivate let detailSegueId = "detail"
    
    private var itemsSubscription: Subscription<[KNOTPlanItemViewModel]>?
    
    override var viewModel: KNOTPlanViewModel! {
        didSet {
            itemsSubscription?.cancel()
            itemsSubscription = viewModel.itemsSubject.listen({ [weak self] (_, _) in
                self?.tableView.reloadData()
            })
            
            do {
                let tast = try viewModel.loadItems(at: Date())
                tast.continueOnErrorWith {
                    print($0)
                }
            } catch let e  {
                //todo: error handle
                assert(false, "\(e)")
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
    
    override func emptyCellDidInsert(at indexPath: IndexPath) {
        do {
            try performSegue(withIdentifier: detailSegueId, sender: viewModel.insertPlan(at: indexPath.row))
        } catch let e {
            //todo: error handle
            assert(false, "\(e)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueId {
            let detailViewModel = sender as! KNOTPlanDetailViewModel
            let detailVC = segue.destination as! KNOTPlanDetailViewController
            detailVC.viewModel = detailViewModel
        }
    }
}

extension KNOTPlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: self.detailSegueId, sender: self.viewModel.planDetailViewModel(at: indexPath.row))
        }
    }
}

class KNOTPlanItemCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var flagView: UIView!
    @IBOutlet weak var flagBackgroundView: UIView!
    @IBOutlet weak var alarmBackgroundView: UIImageView!
    @IBOutlet weak var alarmImageView: UIImageView!
    
    var viewModel: KNOTPlanItemViewModel! {
        didSet {
            itemDidUpdated(viewModel.item)
        }
    }
    
    private func itemDidUpdated(_ item: KNOTPlanItemViewModel.Item?) {
        contentLabel.text = item?.contentText
        flagView.backgroundColor = item?.flagColors.0
        flagView.darkBackgroundColor = item?.flagColors.1
        flagBackgroundView.backgroundColor = item?.flagBkColors.0
        flagBackgroundView.darkBackgroundColor = item?.flagBkColors.1
        alarmBackgroundView.isHidden = item?.alarmColors == nil
        alarmImageView.isHidden = alarmBackgroundView.isHidden
        alarmImageView.tintColor = item?.alarmColors?.0
        alarmImageView.darkTintColor = item?.alarmColors?.1
    }
    
    @IBAction func moreButtonClicked(_ sender: UIButton) {
    }
}

class KNOTPlanEmptyItemCell: UITableViewCell {
}
