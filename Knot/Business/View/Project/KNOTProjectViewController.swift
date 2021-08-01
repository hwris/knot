//
//  KNOTProjectViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/13.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTProjectViewController: KNOTDragAddTableViewController<KNOTProjectViewModel>, UITableViewDelegate {
    fileprivate let detailSegueId = "detail"
    fileprivate let planSegueId = "plan"
    fileprivate let moreSegueId = "more"
    
    private var cellsSubscription: Subscription<ArrayIndexPathSubscription<KNOTProjectCellViewModel>>?
    
    override func viewDidLoad() {
        cellsSubscription?.cancel()
        cellsSubscription = viewModel.projCellViewModelsSubject.listen({ [weak self] (arg0, _) in
            guard let (_, action, indexPaths) = arg0 else {
                return
            }
            
            switch action {
            case .reset:
                self?.tableView.reloadData()
            case .remove:
                self?.tableView.deleteRows(at: indexPaths ?? [], with: .automatic)
            case .update, .insert:
                self?.tableView.reloadRows(at: indexPaths ?? [], with: .automatic)
            }
        })
        
        viewModel.loadProjs().continueOnErrorWith {
            //todo: error handle
            print($0)
        }
    }
    
    deinit {
        cellsSubscription?.cancel()
        cellsSubscription = nil
    }
    
    override var numberOfDateRows: Int {
        return viewModel.projCellViewModelsSubject.value?.0?.count ?? 0
    }
    
    override func dataCell(_ cell: UITableViewCell, didDequeuedAtRow indexPath: IndexPath) {
        let projCell = cell as! KNOTProjectCell
        projCell.viewModel = (viewModel.projCellViewModelsSubject.value?.0)![indexPath.row]
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
        } else if segue.identifier == planSegueId {
            let planVM = sender as! KNOTProjectPlanViewModel
            let planVC = segue.destination as! KNOTProjectPlanViewController
            planVC.viewModel = planVM
        } else if segue.identifier == moreSegueId {
            var cell = sender as? UIView
            while cell != nil, !(cell is UITableViewCell) { cell = cell?.superview }
            if cell == nil { return }
            let index = (tableView.indexPath(for: cell as! UITableViewCell)?.row)!
            let moreVC = segue.destination as! KNOTProjectMoreViewController
            moreVC.viewModel = viewModel.moreViewModel(at: index)
            moreVC.deleteProjFunc = deleteProj
            moreVC.renameProjFunc = renameProj
            moreVC.context = index
        }
    }
    
    private func deleteProj(_ sender: KNOTProjectMoreViewController) {
        let index = sender.context as! Int
        //todo: 加上提示
        viewModel.deleteProj(at: index).continueWith { [weak sender] (t) in
            if let e = t.error {
                assert(false, e.localizedDescription)
                //todo: handle error
                return
            }
            sender?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func renameProj(_ sender: KNOTProjectMoreViewController) {
        let index = sender.context as! Int
        let detailVM = viewModel.detailViewModel(at: index)
        sender.dismiss(animated: false, completion: nil)
        performSegue(withIdentifier: detailSegueId, sender: detailVM)
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let planVM = viewModel.plansViewModel(at: indexPath.row)
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: self.planSegueId, sender: planVM)
        }
    }
}

class KNOTProjectCell: UITableViewCell {
    @IBOutlet weak var itemsView: UIView!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var textBackgroundView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    
    var viewModel: KNOTProjectCellViewModel! {
        didSet {
            contentLabel.text = viewModel.content
            textBackgroundView.backgroundColor = viewModel.colors.flagBkColors.0
            textBackgroundView.darkBackgroundColor = viewModel.colors.flagBkColors.1
            folderImageView.tintColor = viewModel.colors.flagBkColors.0
            folderImageView.darkTintColor = viewModel.colors.flagBkColors.1
            pinImageView.image = UIImage(named: viewModel.colors.flagImageName)
            itemsView.backgroundColor = viewModel.colors.itemsViewBkColors.0
            itemsView.darkBackgroundColor = viewModel.colors.itemsViewBkColors.1
            updateItemsView()
        }
    }
    
    private func updateItemsView() {
        itemsView.removeAllSubviews()
        if let itemViews = viewModel.cachedContent as? [UIView] {
            itemViews.forEach {
                self.itemsView.addSubview($0)
                self.itemsView.sendSubviewToBack($0)
            }
            return
        }
        
        var x = CGFloat(0)
        let itemViews = viewModel.itemColors.map { (color: UIColor) -> UIView in
            let view = UIView(frame: CGRect(x: x, y: 0, width: 32, height: itemsView.bounds.height))
            view.backgroundColor = color
            view.setRoundCorners(.topRight, cornerRadii: 16)
            self.itemsView.addSubview(view)
            self.itemsView.sendSubviewToBack(view)
            x += view.frame.width * 0.5
            return view
        }
        viewModel.cachedContent = itemViews
    }
}
