//
//  KNOTProjectViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/13.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTProjectViewController: KNOTHomeItemTableViewController<KNOTProjectViewModel> {
    fileprivate let detailSegueId = "detail"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var numberOfDateRows: Int {
        return 0
    }
    
    override func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        
    }
    
    override func emptyCellDidInsert(at indexPath: IndexPath) {
        let detailVM = viewModel.insertProj(at: indexPath.row)
        performSegue(withIdentifier: detailSegueId, sender: detailVM)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueId {
            let detailViewModel = sender as! KNOTProjectDetailViewModel
            let detailVC = segue.destination as! KNOTProjectDetailViewController
            detailVC.viewModel = detailViewModel
        }
    }
}

class KNOTProjectCell: UITableViewCell {
    @IBOutlet weak var itemsView: UIView!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var textBackgroundView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
}
