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
import CVCalendar

class KNOTPlanViewController: KNOTHomeItemTableViewController<KNOTPlanViewModel> {
    fileprivate let detailSegueId = "detail"
    
    @IBOutlet weak var calendarView: KNOTCalendarView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var calendarViewTop: NSLayoutConstraint!
    
    private var itemsSubscription: Subscription<CollectionSubscription<[KNOTPlanItemViewModel]>>?
    
    override var viewModel: KNOTPlanViewModel! {
        didSet {
            itemsSubscription?.cancel()
            itemsSubscription = viewModel.itemsSubject.listen({ [weak self] (a, _) in
                guard let (_, action) = a, action == .reset else {
                    return
                }
                self?.tableView.reloadData()
            })
            
            loadItems(at: Date())
        }
    }
    
    deinit {
        itemsSubscription?.cancel()
        itemsSubscription = nil
    }
    
    override var numberOfDateRows: Int {
        return viewModel?.itemsSubject.value?.0?.count ?? 0;
    }
    
    override func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        let itemCell = cell as! KNOTPlanItemCell
        itemCell.viewModel = (viewModel.itemsSubject.value?.0)![indexPath.row]
        itemCell.doneButtonClicked = doneButtonClickedInCell(_:)
    }
    
    override func emptyCellDidInsert(at indexPath: IndexPath) {
        let detailViewModel = viewModel.insertPlan(at: indexPath.row)
        showDetailViewController(at: indexPath, insert: detailViewModel)
    }
    
    private func showDetailViewController(at indexPath: IndexPath, insert detailViewModel: KNOTPlanDetailViewModel? = nil ) {
        let detaiVM = detailViewModel ?? self.viewModel.planDetailViewModel(at: indexPath.row)
        detaiVM.reloadPlan = { [weak self, detailViewModel] (_) in
            let t = self?.viewModel.updatePlan(at: indexPath.row, insert: detailViewModel)
            t?.continueOnErrorWith(continuation: { (e) in
                //todo: error handle
                assert(false, "\(e)")
            })
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        performSegue(withIdentifier: detailSegueId, sender: detaiVM)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueId {
            let detailViewModel = sender as! KNOTPlanDetailViewModel
            let detailVC = segue.destination as! KNOTPlanDetailViewController
            detailVC.viewModel = detailViewModel
        }
    }
    
    @IBAction func calendarViewDidClicked(_ sender: KNOTCalendarView) {
        guard let date = sender.calendarView.presentedDate.convertedDate() else {
            return
        }
        
        loadItems(at: date)
    }
    
    private func loadItems(at date: Date) {
        let tast = viewModel.loadItems(at: date)
        tast.continueOnErrorWith {
            //todo: error handle
            print($0)
        }
    }
    
    @objc
    private func doneButtonClickedInCell(_ cell: KNOTPlanItemCell) {
        
    }
}

extension KNOTPlanViewController: KNOTSwipeTableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView as! KNOTSwipeTableView).didSelectedRowAt(indexPath)
        DispatchQueue.main.async {
            self.showDetailViewController(at: indexPath)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let newConstant = scrollView.contentOffset.y < 0 ? 0 : -self.calendarView.frame.height
        if newConstant == calendarViewTop.constant {
            return
        }
        
        UIView.animate(withDuration: 0.2) {
            self.calendarViewTop.constant = newConstant
            self.view.layoutIfNeeded()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func tableView(_ tableView: UITableView, rowPanGSRecognized gs: UIPanGestureRecognizer, at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? KNOTPlanItemCell {
            cell.rowPanGSRecognized(gs)
        }
    }
    
    func tableView(_ tableView: UITableView, rowPanGSNotBegin gs: UIPanGestureRecognizer, at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? KNOTPlanItemCell {
            cell.rowPanGSNotBegin(gs)
        }
    }
}

class KNOTPlanItemCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var flagView: UIView!
    @IBOutlet weak var flagBackgroundView: UIView!
    @IBOutlet weak var alarmBackgroundView: UIImageView!
    @IBOutlet weak var alarmImageView: UIImageView!
    fileprivate var doneButtonClicked: ((KNOTPlanItemCell) -> ())?
    var viewModel: KNOTPlanItemViewModel! {
        didSet {
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
    
    private func updateContentView(withStrikethrough useStrikethrough: Bool = false) {
        contentLabel.text = nil
        contentLabel.attributedText = nil
        
        if useStrikethrough == false, viewModel.items.isEmpty {
            contentLabel.text = viewModel.content
            return
        }
        
        if useStrikethrough == false, let attText = viewModel.cachedContent as? NSAttributedString {
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
        let range = NSRange(location: viewModel.content.count, length: attText.string.count - viewModel.content.count)
        let attributes = [ NSAttributedString.Key.paragraphStyle : paragraphStyle as Any]
        attText.addAttributes(attributes, range: range)
        
        contentLabel.attributedText = attText
        viewModel.cachedContent = attText
    }
    
    @IBAction func moreButtonClicked(_ sender: UIButton) {
    }
    
    private var doneView: UIView!
    private var startOffsetX = CGFloat.zero
    private var startScale = CGFloat.zero
    fileprivate func rowPanGSRecognized(_ gs: UIPanGestureRecognizer) {
        if doneView == nil, gs.translation(in: contentView).x <= 0.01 {
            return
        }
        
        switch gs.state {
        case .began:
            startOffsetX = flagBackgroundView.transform.tx
            startScale = doneView?.transform.a ?? 0
            
            if doneView != nil {
                return
            }
            
            let button = UIButton(type: .custom)
            button.backgroundColor = flagView.backgroundColor
            button.cornerRadius = 20
            button.clipsToBounds = true
            button.setBackgroundImage(UIImage(named: viewModel.colors.flagImageName), for: .normal)
            button.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
            
            contentView.insertSubview(button, at: 0)
            button.frame = CGRect(x: 20, y: 0, width: 40, height: 40)
            button.center.y = contentView.center.y
            button.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            doneView = button
            
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .changed:
            guard let doneView = self.doneView else {
                return
            }
            
            let offsetX = gs.translation(in: contentView).x
            flagBackgroundView.transform = CGAffineTransform(translationX: max(0, startOffsetX + offsetX), y: 0)
            
            let scale = min(max(startScale + offsetX * 0.01, 0), 1.0)
            doneView.transform = CGAffineTransform(scaleX: scale, y: scale)
        case .ended:
            guard let doneView = self.doneView else {
                return
            }
            
            let shouldDone = doneView.transform.a >= 0.5
            UIView.animate(withDuration: 0.2, animations: {
                doneView.transform = shouldDone ? .identity : CGAffineTransform(scaleX: 0, y: 0)
                self.flagBackgroundView.transform =
                    shouldDone ? CGAffineTransform(translationX: self.doneView.frame.width + 20, y: 0) : .identity
                self.updateContentView(withStrikethrough: shouldDone)
            }, completion: { _ in
                if !shouldDone {
                    doneView.removeFromSuperview()
                    self.doneView = nil
                }
            })
        case .cancelled, .failed:
            guard let doneView = self.doneView else {
                return
            }
            
            doneView.removeFromSuperview()
            self.doneView = nil
            flagBackgroundView.transform = .identity
        default:
            break
        }
    }
    
    fileprivate func rowPanGSNotBegin(_ gs: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.2, animations: {
            self.flagBackgroundView?.transform = .identity
            self.doneView?.transform = CGAffineTransform(scaleX: 0, y: 0)
        }, completion: { _ in
            self.doneView?.removeFromSuperview()
            self.doneView = nil
        })
    }
    
    @objc
    private func doneButtonTouched(_ sender: UIButton) {
        doneButtonClicked?(self)
    }
}

class KNOTPlanEmptyItemCell: UITableViewCell {
}

class KNOTCalendarView: UIControl, CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateDataLable(with: calendarView.presentedDate)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    @IBAction func switchCalendarModel(_ sender: UIButton) {
        let isToMonthView = calendarView.calendarMode == .weekView
        calendarView.changeMode(isToMonthView ? .monthView : .weekView)
        sender.isSelected = isToMonthView
    }
    
    func presentationMode() -> CalendarMode {
        return .weekView
    }
    
    func firstWeekday() -> Weekday {
        return .sunday
    }
    
    func weekdaySymbolType() -> WeekdaySymbolType {
        return .veryShort
    }
    
    func presentedDateUpdated(_ date: CVDate) {
        updateDataLable(with: date)
        sendActions(for: .touchUpInside)
    }
    
    private func updateDataLable(with date: CVDate) {
        dateLabel.text = "\(date.year).\(date.month)"
    }
}
