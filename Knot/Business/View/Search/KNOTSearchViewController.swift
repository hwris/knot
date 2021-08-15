//
//  KNOTSearchViewController.swift
//  Knot
//
//  Created by 苏杨 on 2021/8/8.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import UIKit

class KNOTSearchViewController: UIViewController {
    private var searchResultSubscription: Subscription<KNOTSearchViewModel.SearchResultViewModel>?
    private var searchWorkItem: DispatchWorkItem?
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var searchViewLeading: NSLayoutConstraint!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    var viewModel: KNOTSearchViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitleColor(UIColor(0xFFFFFF, 0.87, 0x070D20, 1.0), for: .normal)
        searchTextField.becomeFirstResponder()
        resultTableView.register(KNOTSearchDescView.self, forHeaderFooterViewReuseIdentifier: "desc")
        
        searchResultSubscription = viewModel.searchResult.listen({ [weak self] _, _ in
            self?.resultTableView.reloadData()
        }, needNotify: false)
    }
    
    @IBAction func cancelButtonClicked(_ sender: UIButton) {
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "plan" {
            let cell = sender as! UITableViewCell
            let indexPath = resultTableView.indexPath(for: cell)!
            let vm = viewModel.planDetailViewModel(at: indexPath)
            let vc = segue.destination as! KNOTPlanDetailViewController
            vc.viewModel = vm
        } else if segue.identifier == "proj" {
            let cell = sender as! UITableViewCell
            let indexPath = resultTableView.indexPath(for: cell)!
            let vm = viewModel.projDetailViewModel(at: indexPath)
            let vc = segue.destination as! KNOTProjectDetailViewController
            vc.viewModel = vm
        } else {
            super .prepare(for: segue, sender: sender)
        }
    }
}

extension KNOTSearchViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        searchWorkItem?.cancel()
        let searchWorkItem = DispatchWorkItem { [weak self] in
            self?.viewModel.search(with: text)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: searchWorkItem)
        self.searchWorkItem = searchWorkItem
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}

extension KNOTSearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSectionsInTableView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.tableView(numberOfRowsInSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = indexPath.section == 0 ? "proj" : "plan"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! KNOTSearchCell
        cell.viewModel = viewModel.tableView(cellViewModelForRowAt: indexPath)
        return cell
    }
}

extension KNOTSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "desc") as! KNOTSearchDescView
        view.desc = viewModel.tableView(descForFooterInSection: section)
        return view
    }
}

class KNOTSearchCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    
    var viewModel: KNOTSearchViewModel.SearchItemViewModel! {
        didSet {
            contentLabel.text = viewModel.title
        }
    }
}

class KNOTSearchProjCell: KNOTSearchCell {
    @IBOutlet weak var countLabel: UILabel!
    
    override var viewModel: KNOTSearchViewModel.SearchItemViewModel! {
        didSet {
            countLabel.text = viewModel.subTitle
        }
    }
}

class KNOTSearchPlanCell: KNOTSearchCell {
}

class KNOTSearchDescView: UITableViewHeaderFooterView {
    private var _contentLabel: UILabel!
    
    private var contentLabel: UILabel {
        if _contentLabel != nil {
            return _contentLabel
        }
        
        _contentLabel = UILabel()
        _contentLabel.font = UIFont.systemFont(ofSize: 16)
        _contentLabel.textColor = UIColor(0x5276FF)
        _contentLabel.textAlignment = .center
        
        contentView.addSubview(_contentLabel)
        _contentLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(21)
            $0.bottom.top.equalTo(0)
        }
        
        if #available(iOS 14.0, *) {
            var config = UIBackgroundConfiguration.clear()
            config.backgroundColor = .clear
            backgroundConfiguration = config
        } else {
            backgroundView = UIView()
            backgroundView?.backgroundColor = .clear
        }
        contentView.backgroundColor = .clear
        
        return _contentLabel
    }
    
    var desc: String? {
        get { contentLabel.text }
        set { contentLabel.text = newValue }
    }
}
