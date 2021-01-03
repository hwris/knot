//
//  UITableView+Swipe.swift
//  Knot
//
//  Created by 苏杨 on 2021/1/3.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTSwipeTableView: UITableView {
    private weak var rowPanGS: KNOTSwipeTableViewRowPanGS?
    
    override var delegate: UITableViewDelegate? {
        didSet {
            if delegate is KNOTSwipeTableViewDelegate {
                let rowPanGS = KNOTSwipeTableViewRowPanGS(tableView: self)
                addGestureRecognizer(rowPanGS)
                self.rowPanGS = rowPanGS
            }
        }
    }
    
    func didSelectedRowAt(_ indexPath: IndexPath) {
        rowPanGS?.tableViewDidSelectedRowAt(indexPath)
    }
}

@objc protocol KNOTSwipeTableViewDelegate: UITableViewDelegate {
    @objc optional func tableView(_ tableView: UITableView, rowPanGSRecognized gs: UIPanGestureRecognizer, at indexPath: IndexPath)
    @objc optional func tableView(_ tableView: UITableView, rowPanGSNotBegin gs: UIPanGestureRecognizer, at indexPath: IndexPath)
}

private class KNOTSwipeTableViewRowPanGS: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    private weak var tableView: UITableView?
    private weak var tableViewDelegate: KNOTSwipeTableViewDelegate?
    private var currentIndexPath: IndexPath?
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init(target: nil, action: nil)
        delegate = self
        addTarget(self, action: #selector(rowPanGSDidRecognized(sender:)))
        tableView.panGestureRecognizer.require(toFail: self)
        tableViewDelegate = tableView.delegate as? KNOTSwipeTableViewDelegate
    }
    
    @objc private func rowPanGSDidRecognized(sender: UIPanGestureRecognizer) {
        guard let tableView = self.tableView, let indexpath = currentIndexPath else {
            return
        }
        
        tableViewDelegate?.tableView?(tableView, rowPanGSRecognized: self, at: indexpath)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let tableView = self.tableView else {
            currentIndexPath = nil
            return false
        }
        
        let t = (gestureRecognizer as! UIPanGestureRecognizer).translation(in: tableView)
        let shouldBegin = fabsf(Float(t.x)) > fabsf(Float(t.y))
        
        if shouldBegin {
            guard let newIndexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)) else {
                return true
            }
            
            guard let oldIndexPath = currentIndexPath else {
                currentIndexPath = newIndexPath
                return true
            }
            
            guard oldIndexPath != newIndexPath else {
                return true
            }
            
            tableViewDelegate?.tableView?(tableView, rowPanGSNotBegin: self, at: oldIndexPath)
            currentIndexPath = newIndexPath
        } else {
            if let oldIndexPath = currentIndexPath {
                tableViewDelegate?.tableView?(tableView, rowPanGSNotBegin: self, at: oldIndexPath)
                currentIndexPath = nil
            }
        }
        
        return shouldBegin
    }
    
    fileprivate func tableViewDidSelectedRowAt(_ indexPath: IndexPath) {
        guard let tableView = self.tableView else {
            currentIndexPath = nil
            return
        }
        
        if let oldIndexPath = currentIndexPath {
            tableViewDelegate?.tableView?(tableView, rowPanGSNotBegin: self, at: oldIndexPath)
            currentIndexPath = nil
        }
    }
}
