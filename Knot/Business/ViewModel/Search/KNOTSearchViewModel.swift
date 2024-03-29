//
//  KNOTSearchViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/8/8.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import Foundation

class KNOTSearchViewModel {
    class SearchItemViewModel {
        var title: String?
        var subTitle: String?
        fileprivate var model: Any?
    }
    
    class SearchResultViewModel {
        var projItems: [SearchItemViewModel]?
        var projSearchDesc: String?
        
        var planItems: [SearchItemViewModel]?
        var planSearchDesc: String?
    }
    
    private let model: KNOTSearchModel
    let searchResult = Subject<SearchResultViewModel>()
    
    init(model: KNOTSearchModel) {
        self.model = model
    }
    
    var numberOfSectionsInTableView: Int {
        searchResult.value == nil ? 0 : 2
    }
    
    func tableView(numberOfRowsInSection section: Int) -> Int {
        section == 0 ?
            (searchResult.value?.projItems?.count ?? 0) :
            (searchResult.value?.planItems?.count ?? 0)
    }
    
    func tableView(cellViewModelForRowAt indexPath: IndexPath) -> SearchItemViewModel {
        indexPath.section == 0 ?
            searchResult.value!.projItems![indexPath.row] :
            searchResult.value!.planItems![indexPath.row]
    }
    
    func tableView(descForFooterInSection section: Int) -> String? {
        section == 0 ?
            searchResult.value?.projSearchDesc :
            searchResult.value?.planSearchDesc
    }
    
    func search(with _text: String?) {
        guard let text = _text, !text.isEmpty else {
            searchResult.publish(nil)
            return
        }
        
        let (planResult, projResult) = model.search(with: text)
        
        let searchResultViewModel = SearchResultViewModel()
        searchResultViewModel.planItems = planResult.map {
            let vm = SearchItemViewModel()
            vm.title = $0.content
            vm.model = $0
            return vm
        }
        searchResultViewModel.planSearchDesc = NSLocalizedString("Search plan:", comment: "") + " \(text)"
        searchResultViewModel.projItems = projResult.map {
            let vm = SearchItemViewModel()
            vm.title = $0.name
            vm.subTitle = "\($0.plans?.count ?? 0)" + NSLocalizedString(" plan(s)", comment: "")
            vm.model = $0
            return vm
        }
        searchResultViewModel.projSearchDesc = NSLocalizedString("Search project:", comment: "") + " \(text)"
        
        searchResult.publish(searchResultViewModel)
    }
    
    func planDetailViewModel(at indexPath: IndexPath) -> KNOTPlanDetailViewModel {
        let vm = tableView(cellViewModelForRowAt: indexPath)
        let plan = vm.model as! KNOTPlanEntity
        let model = model.planDetailModel(with: plan)
        return KNOTPlanDetailViewModel(model: model)
    }
    
    func projDetailViewModel(at indexPath: IndexPath) -> KNOTProjectDetailViewModel {
        let vm = tableView(cellViewModelForRowAt: indexPath)
        let proj = vm.model as! KNOTProjectEntity
        let model = model.projectDetailModel(with: proj)
        return KNOTProjectDetailViewModel(model: model)
    }
}
