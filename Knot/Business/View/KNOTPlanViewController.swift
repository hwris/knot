//
//  KNOTPlanViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/4.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit
import BoltsSwift
import SnapKit

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
    private var itemsView: UIView?
    
    var viewModel: KNOTPlanItemViewModel! {
        didSet {
            if oldValue === viewModel {
                return
            }
            
            contentLabel.text = viewModel.content
            flagView.backgroundColor = viewModel.colors.flagColors.0
            flagView.darkBackgroundColor = viewModel.colors.flagColors.1
            flagBackgroundView.backgroundColor = viewModel.colors.flagBkColors.0
            flagBackgroundView.darkBackgroundColor = viewModel.colors.flagBkColors.1
            alarmBackgroundView.isHidden = viewModel.colors.alarmColors == nil
            alarmImageView.isHidden = alarmBackgroundView.isHidden
            alarmImageView.tintColor = viewModel.colors.alarmColors?.0
            alarmImageView.darkTintColor = viewModel.colors.alarmColors?.1
            
//            updateItemsView()
        }
    }
    
    private func updateItemsView() {
        itemsView?.removeFromSuperview()
        itemsView = nil
        
        if viewModel.items.isEmpty {
            return
        }
        
        let view = contentLabel.superview!
        let itemsStackView = UIStackView()
        itemsStackView.axis = .vertical
        itemsStackView.alignment = .fill
        itemsStackView.distribution = .fill
        itemsStackView.spacing = 30.0
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for item in viewModel.items {
            let isDoneImage = UIImageView(image: UIImage(named: item.isDoneButtonSelected ? "ic_select_on_blue" : "ic_select_off_blue"))
            isDoneImage.contentMode = .center;
            isDoneImage.setContentHuggingPriority(.required, for: .horizontal)
            isDoneImage.setContentCompressionResistancePriority(.required, for: .horizontal)
            isDoneImage.setContentHuggingPriority(.required, for: .vertical)
            isDoneImage.setContentCompressionResistancePriority(.required, for: .vertical)
            isDoneImage.translatesAutoresizingMaskIntoConstraints = false
            isDoneImage.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 18, height: 18))
            }
            
            let itemContenLabel = UILabel()
            itemContenLabel.text = item.content
            itemContenLabel.font = UIFont.systemFont(ofSize: 16)
            itemContenLabel.textColor = UIColor(UInt32(0xFFFFFF), UInt32(0x070D20))
            itemContenLabel.alpha = item.isDoneButtonSelected ? 0.5 : 1.0
            itemContenLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            itemContenLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            itemContenLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
            itemContenLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            itemContenLabel.numberOfLines = 0
            itemContenLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let itemStackView = UIStackView(arrangedSubviews: [ isDoneImage, itemContenLabel ])
            itemStackView.axis = .horizontal
            itemStackView.alignment = .center
            itemStackView.distribution = .fill
            itemStackView.spacing = 15.0
            itemStackView.translatesAutoresizingMaskIntoConstraints = false
            
            itemsStackView.addArrangedSubview(itemStackView)
        }
        
        contentLabel.superview?.addSubview(itemsStackView)
        itemsStackView.snp.makeConstraints {
            $0.leading.equalTo(self.contentLabel.snp.leading)
            $0.trailing.equalTo(self.contentLabel.snp.trailing)
            $0.top.equalTo(self.contentLabel.snp.bottom).offset(30.0)
            $0.bottom.equalTo(-30.0)
        }
        
        itemsView = itemsStackView
    }
    
    @IBAction func moreButtonClicked(_ sender: UIButton) {
    }
}

class KNOTPlanEmptyItemCell: UITableViewCell {
}
