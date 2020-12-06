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
    
    var viewModel: KNOTPlanItemViewModel! {
        didSet {
            if oldValue === viewModel {
                return
            }
            
            flagView.backgroundColor = viewModel.colors.flagColors.0
            flagView.darkBackgroundColor = viewModel.colors.flagColors.1
            flagBackgroundView.backgroundColor = viewModel.colors.flagBkColors.0
            flagBackgroundView.darkBackgroundColor = viewModel.colors.flagBkColors.1
            alarmBackgroundView.isHidden = viewModel.colors.alarmColors == nil
            alarmImageView.isHidden = alarmBackgroundView.isHidden
            alarmImageView.tintColor = viewModel.colors.alarmColors?.0
            alarmImageView.darkTintColor = viewModel.colors.alarmColors?.1
            
            updateContentView()
        }
    }
    
    private func updateContentView() {
        contentLabel.text = nil
        contentLabel.attributedText = nil
        
        if viewModel.items.isEmpty {
            contentLabel.text = viewModel.content
            return
        }
        
        if let attText = viewModel.cachedContent as? NSAttributedString {
            contentLabel.attributedText = attText
            return
        }
        
        let attText = NSMutableAttributedString(string: viewModel.content + "\n")
        attText.addAttributes([.font : UIFont.systemFont(ofSize: 18, weight: .medium),
                               .foregroundColor : UIColor(UInt32(0xFFFFFF), 0.87, UInt32(0x070D20), 1.0)],
                              range: NSRange(location: 0, length: viewModel.content.count))
        for item in viewModel.items {
            let isDoneImage = NSTextAttachment()
            isDoneImage.image = UIImage(named: item.isDoneButtonSelected ? "ic_select_on_blue" : "ic_select_off_blue")
            isDoneImage.bounds = CGRect(x: 0, y: -4, width: 18, height: 18)
            let isDoneImageAttText = NSAttributedString(attachment: isDoneImage)
            let itemContenAttText = NSAttributedString(string: "  " + item.content + (item === viewModel.items.last ? "" : "\n"),
                                                       attributes: [.font : UIFont.systemFont(ofSize: 16),
                                                                    .foregroundColor : UIColor(UInt32(0xFFFFFF),
                                                                                               item.isDoneButtonSelected ? 0.5 : 0.87,
                                                                                               UInt32(0x070D20),
                                                                                               item.isDoneButtonSelected ? 0.5 : 1.0)])
            attText.append(isDoneImageAttText)
            attText.append(itemContenAttText)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 26
        paragraphStyle.paragraphSpacingBefore = 30
        attText.addAttribute(.paragraphStyle,
                             value: paragraphStyle,
                             range: NSRange(location: viewModel.content.count, length: attText.string.count - viewModel.content.count))
        
        contentLabel.attributedText = attText
        viewModel.cachedContent = attText
    }
    
    @IBAction func moreButtonClicked(_ sender: UIButton) {
    }
}

class KNOTPlanEmptyItemCell: UITableViewCell {
}
