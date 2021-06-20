//
//  KNOTHomeViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTHomeViewController: UIViewController {
    @IBOutlet private var buttons: [KNOTButton]!
    @IBOutlet private weak var addButton: KNOTHomeAddButton!
    fileprivate var snapshotAddButton: UIView?
    private weak var _tabBarController: UITabBarController!
    
    var viewModel: KNOTViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttons.forEach {
            $0.setTitleColor(UIColor(0xFFFFFF, 0.7, 0x070D20, 1.0), for: .normal)
            $0.setTitleColor(UIColor(0xFFFFFF, 0.87, 0x5276FF, 1.0), for: .selected)
            
            let darkImage = UIImage.fromColor(color: UIColor(0xFFFFFF, 0.04), cornerRadius: 22.0)
            let lightImage = UIImage.fromColor(color: UIColor(0xF5F6F9, 1.0), cornerRadius: 22.0)
            $0.setBackgroundImage(dynamicProvider: {
                return $0 == .dark ? darkImage : lightImage
            }, for: .selected)
        }
        
        let addImage = UIImage.fromColor(color: UIColor(0x5276FF), cornerRadius: 28.0)
        let deleteLightImage = UIImage.fromColor(color: UIColor(0x545865), cornerRadius: 28.0)
        let deleteDarkImage = UIImage.fromColor(color: UIColor(0xffffff, 0.12), cornerRadius: 28.0)
        addButton.setBackgroundImage(dynamicProvider: {_ in
            return addImage;
        }, for: .normal)
        addButton.setBackgroundImage(dynamicProvider: {
            return $0 == .dark ? deleteDarkImage : deleteLightImage;
        }, for: .selected)
        addButton.delegate = self
        
        _tabBarController = children.first as? UITabBarController
        buttonDidClicked(buttons[0])
    }
    
    fileprivate var selectedItemViewController: UIViewController & KNOTHomeItemViewController {
        return _tabBarController.selectedViewController as! UIViewController & KNOTHomeItemViewController
    }
    
    @IBAction func buttonDidClicked(_ sender: KNOTButton) {
        if (sender.isSelected) {
            return
        }
        
        buttons.forEach { $0.isSelected = sender == $0 }
        let index = buttons.firstIndex(of: sender)!
        setViewModelForSelectedItemViewController(_tabBarController.viewControllers![index])
        _tabBarController.selectedIndex = index
    }
    
    private func setViewModelForSelectedItemViewController(_ vc: UIViewController) {
        if let planVC = vc as? KNOTPlanViewController, planVC.viewModel == nil {
            planVC.viewModel = viewModel.planViewModel
        } else if let projVC = vc as? KNOTProjectViewController, projVC.viewModel == nil {
            projVC.viewModel = viewModel.projectViewModel
        }
    }
}

extension KNOTHomeViewController: KNOTHomeAddButtonDelegate {
    func addButton(_ button: KNOTHomeAddButton, beginTracking touch: UITouch, with event: UIEvent?) {
        if let snapshotAddButton = button.snapshotView(afterScreenUpdates: false) {
            snapshotAddButton.alpha = 0
            self.snapshotAddButton = snapshotAddButton
            view.addSubview(snapshotAddButton)
        }
        
        button.isSelected = true
        
        if #available(iOS 10.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        selectedItemViewController.homeViewController(self, addButton: button, continueTracking: touch)
    }
    
    func addButton(_ button: KNOTHomeAddButton, continueTracking touch: UITouch, with event: UIEvent?) {
        let inButton = button.bounds.contains(touch.location(in: button))
        snapshotAddButton?.alpha = inButton ? 0 : 1.0
        snapshotAddButton?.center = touch.location(in: view)
        
        selectedItemViewController.homeViewController(self, addButton: button, continueTracking: touch)
    }
    
    func addButton(_ button: KNOTHomeAddButton, endTracking touch: UITouch?, with event: UIEvent?) {
        snapshotAddButton?.removeFromSuperview()
        snapshotAddButton = nil
        
        button.isSelected = false
        
        var isEndInAddbutton = false
        if let p = touch?.location(in: button), button.bounds.contains(p) {
            isEndInAddbutton = true
        }
        
        selectedItemViewController.homeViewController(self,
                                                      addButton: addButton,
                                                      endTracking:touch,
                                                      inAddButton: isEndInAddbutton)
    }
    
    func addButton(_ button: KNOTHomeAddButton, cancelTrackingWith event: UIEvent?) {
        addButton(button, endTracking: nil, with: event)
    }
}

protocol KNOTHomeItemViewController {
    func homeViewController(_ homeViewController: KNOTHomeViewController,
                            addButton button: UIButton,
                            continueTracking touch: UITouch)
    func homeViewController(_ homeViewController: KNOTHomeViewController,
                            addButton button: UIButton,
                            endTracking touch: UITouch?,
                            inAddButton: Bool)
}

class KNOTHomeAddButton: KNOTButton {
    weak var delegate: (AnyObject & KNOTHomeAddButtonDelegate)?
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let r = super.beginTracking(touch, with: event)
        if r {
            delegate?.addButton(self, beginTracking: touch, with: event)
        }
        return r
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let r = super.continueTracking(touch, with: event)
        if r {
            delegate?.addButton(self, continueTracking: touch, with: event)
        }
        return r;
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        delegate?.addButton(self, endTracking: touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        delegate?.addButton(self, cancelTrackingWith: event)
    }
}

protocol KNOTHomeAddButtonDelegate {
    func addButton(_ button: KNOTHomeAddButton, beginTracking touch: UITouch, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, continueTracking touch: UITouch, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, endTracking touch: UITouch?, with event: UIEvent?)
    func addButton(_ button: KNOTHomeAddButton, cancelTrackingWith event: UIEvent?)
}

class KNOTHomeItemTableViewController<T>: UIViewController, UITableViewDataSource {
    let dataCellId = "cell"
    let emptyCellId = "empty"
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate var emptyIndexPath: IndexPath?
    fileprivate var isTrackingOutInAddButton = false
    
    var viewModel: T!
    
    var numberOfDateRows: Int {
        return 0;
    }
    
    func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        
    }
    
    func emptyCellDidInsert(at indexPath: IndexPath) {
        
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (emptyIndexPath != nil) ? numberOfDateRows + 1 : numberOfDateRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let _emptyIndexPath = emptyIndexPath else {
            let cell = tableView.dequeueReusableCell(withIdentifier: dataCellId, for: indexPath)
            dataCell(cell, didDequeuedAtRow: indexPath)
            return cell
        }
        
        let isEmptyCell = _emptyIndexPath == indexPath
        let cell = tableView.dequeueReusableCell(withIdentifier: isEmptyCell ? emptyCellId : dataCellId, for: indexPath)
        
        if !isEmptyCell {
            let realRow = indexPath.row > _emptyIndexPath.row ? indexPath.row - 1 : indexPath.row
            let realIndexPath = IndexPath(row: realRow, section: indexPath.section)
            dataCell(cell, didDequeuedAtRow: realIndexPath)
        }
        
        return cell
    }
}

extension KNOTHomeItemTableViewController: KNOTHomeItemViewController {
    func homeViewController(_ homeViewController: KNOTHomeViewController, addButton button: UIButton, continueTracking touch: UITouch) {
        if !button.bounds.contains(touch.location(in: button)), !isTrackingOutInAddButton {
            isTrackingOutInAddButton = true
        }
        
        guard let _emptyIndexPath = emptyIndexPath else {
            emptyIndexPath = IndexPath(row: numberOfDateRows, section: 0)
            tableView.insertRows(at: [ emptyIndexPath! ], with: .none)
            return
        }
        
        let point = touch.location(in: view)
        
        if point.y < tableView.frame.minY {
            let targetIndexPath = IndexPath(row: max(_emptyIndexPath.row - 1, 0), section: _emptyIndexPath.section)
            tableView.scrollToRow(at: targetIndexPath, at: .top, animated: true)
        } else if point.y > tableView.frame.maxY {
            let allRows = tableView.dataSource?.tableView(tableView, numberOfRowsInSection: _emptyIndexPath.section) ?? 0
            let targetIndexPath = IndexPath(row: min(_emptyIndexPath.row + 1, allRows - 1), section: _emptyIndexPath.section)
            tableView.scrollToRow(at: targetIndexPath, at: .bottom, animated: true)
        } else {
            let pointInTableView = touch.location(in: tableView)
            guard let indexpath = tableView.indexPathForRow(at: pointInTableView) else {
                return
            }
            
            if _emptyIndexPath == indexpath {
                let visibleRows = tableView.indexPathsForVisibleRows
                if _emptyIndexPath == visibleRows?.first {
                    let targetIndexPath = IndexPath(row: max(_emptyIndexPath.row - 1, 0), section: _emptyIndexPath.section)
                    tableView.scrollToRow(at: targetIndexPath, at: .top, animated: true)
                } else if indexpath == visibleRows?.last {
                    let allRows = tableView.dataSource?.tableView(tableView, numberOfRowsInSection: indexpath.section) ?? 0
                    let targetIndexPath = IndexPath(row: min(_emptyIndexPath.row + 1, allRows - 1), section: _emptyIndexPath.section)
                    tableView.scrollToRow(at: targetIndexPath, at: .bottom, animated: true)
                }
            } else {
                emptyIndexPath = indexpath
                if indexpath.row > _emptyIndexPath.row {
                    tableView.moveRow(at: _emptyIndexPath, to: emptyIndexPath!)
                } else {
                    tableView.moveRow(at: emptyIndexPath!, to: _emptyIndexPath)
                }
                
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
    
    func homeViewController(_ homeViewController: KNOTHomeViewController,
                            addButton button: UIButton,
                            endTracking touch: UITouch?,
                            inAddButton: Bool) {
        if inAddButton, isTrackingOutInAddButton, let _emptyIndexPath = emptyIndexPath {
            isTrackingOutInAddButton = false
            emptyIndexPath = nil
            tableView.deleteRows(at: [ _emptyIndexPath ], with: .bottom)
            return;
        }
        
        if !isTrackingOutInAddButton, let _emptyIndexPath = emptyIndexPath {
            tableView.scrollToRow(at: _emptyIndexPath, at: .bottom, animated: true)
        }
        
        isTrackingOutInAddButton = false
        if let _emptyIndexPath = emptyIndexPath {
            emptyIndexPath = nil
            emptyCellDidInsert(at: _emptyIndexPath)
        }
    }
}
