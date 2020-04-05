//
//  KNOTHomeItemTableViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/4.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class KNOTHomeItemTableViewController: UIViewController, UITableViewDataSource {
    let dataCellId = "cell"
    let emptyCellId = "empty"
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate var emptyIndexPath: IndexPath?
    fileprivate var isTrackingOutInAddButton = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var  numberOfDateRows: Int {
        return 0;
    }
    
    func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (emptyIndexPath != nil) ? numberOfDateRows + 1 : numberOfDateRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let _emptyIndexPath = emptyIndexPath else {
            let cell = tableView.dequeueReusableCell(withIdentifier: dataCellId, for: indexPath)
            dataCell(cell, didDequeuedAtRow: indexPath)
            cell.textLabel?.text = "\(indexPath.row)"
            return cell
        }
        
        let isEmptyCell = _emptyIndexPath == indexPath
        let cell = tableView.dequeueReusableCell(withIdentifier: isEmptyCell ? emptyCellId : dataCellId, for: indexPath)
        
        if !isEmptyCell {
            let realRow = indexPath.row > _emptyIndexPath.row ? indexPath.row - 1 : indexPath.row
            let realIndexPath = IndexPath(row: realRow, section: indexPath.section)
            cell.textLabel?.text = "\(realRow)"
            dataCell(cell, didDequeuedAtRow: realIndexPath)
        }
        
        return cell
    }
}

extension KNOTPlanViewController: KNOTHomeItemViewController {
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
                
                if #available(iOS 10.0, *) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
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
        }
        
        if !isTrackingOutInAddButton, let _emptyIndexPath = emptyIndexPath {
            tableView.scrollToRow(at: _emptyIndexPath, at: .bottom, animated: true)
        }
        
        isTrackingOutInAddButton = false
    }
}
