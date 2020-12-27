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
    
    private var itemsSubscription: Subscription<[KNOTPlanItemViewModel]>?
    
    override var viewModel: KNOTPlanViewModel! {
        didSet {
            itemsSubscription?.cancel()
            itemsSubscription = viewModel.itemsSubject.listen({ [weak self] (_, _) in
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
    
    @IBAction func calendarViewDidClicked(_ sender: KNOTCalendarView) {
        guard let date = sender.calendarView.presentedDate.convertedDate() else {
            return
        }
        
        loadItems(at: date)
    }
    
    private func loadItems(at date: Date) {
        do {
            let tast = try viewModel.loadItems(at: date)
            tast.continueOnErrorWith {
                print($0)
            }
        } catch let e  {
            //todo: error handle
            assert(false, "\(e)")
        }
    }
}

extension KNOTPlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: self.detailSegueId, sender: self.viewModel.planDetailViewModel(at: indexPath.row))
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
}

class KNOTPlanItemCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var flagView: UIView!
    @IBOutlet weak var flagBackgroundView: UIView!
    @IBOutlet weak var alarmBackgroundView: UIImageView!
    @IBOutlet weak var alarmImageView: UIImageView!
    private var doneView: UIView!
    
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
    
    private var startPoint: CGPoint!
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tableView?.panGestureRecognizer.isEnabled = false
        let doneView = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        doneView.backgroundColor = flagView.backgroundColor
        doneView.cornerRadius = 20
        doneView.clipsToBounds = true
        doneView.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        doneView.textColor = .white
        doneView.text = "√"
        doneView.textAlignment = .center
        
        contentView.addSubview(doneView)
        doneView.center.y = contentView.center.y
        
        doneView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        startPoint = touches.first!.location(in: contentView)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        self.doneView = doneView
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let offset = touches.first!.location(in: contentView).x - startPoint.x
        var scale = offset * 0.01
        scale = scale <= 0.001 ? 0.001 : scale >= 1 ? 1 : scale
        doneView.transform = CGAffineTransform(scaleX: scale, y: scale)
        flagBackgroundView.transform = CGAffineTransform(translationX: offset, y: 0)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tableView?.panGestureRecognizer.isEnabled = true
        let shouldDone = doneView.transform.a >= 1.0
        UIView.animate(withDuration: 0.2) {
            self.flagBackgroundView.transform =
                shouldDone ? CGAffineTransform(translationX: self.doneView.frame.maxX + 20, y: 0) : .identity
            self.doneView.transform = shouldDone ? .identity : CGAffineTransform(scaleX: 0.001, y: 0.001)
        } completion: { _ in
            if shouldDone {
//                viewModel.doDone
            } else {
                self.doneView.removeFromSuperview()
                self.doneView = nil
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tableView?.panGestureRecognizer.isEnabled = true
        doneView.removeFromSuperview()
        doneView = nil
        flagBackgroundView.transform = .identity
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
