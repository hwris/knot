//
//  KNOTProjectViewModel.swift
//  Knot
//
//  Created by 苏杨 on 2021/6/13.
//  Copyright © 2021 SUYANG. All rights reserved.
//

import BoltsSwift

class KNOTProjectViewModel {
    private let model: KNOTProjectModel
    private var projsSubscription: Subscription<ArraySubscription<KNOTProjectEntity>>?
    let projCellViewModelsSubject = Subject<ArrayIndexPathSubscription<KNOTProjectCellViewModel>>()
    
    init(model: KNOTProjectModel) {
        self.model = model
        projsSubscription = self.model.projectsSubject.listen({ [weak self] new, old in
            guard let (projs, action, _) = new, action == .reset else {
                return
            }
            
            self?.publishProjs(projs ?? [])
        })
    }
    
    deinit {
        projsSubscription?.cancel()
        projsSubscription = nil
    }
    
    private func publishProjs(_ projs: [KNOTProjectEntity]) {
        let projCellViewModels = projs.sorted(by: { $0.priority > $1.priority })
            .map({ KNOTProjectCellViewModel(model: $0) })
        projCellViewModelsSubject.publish((projCellViewModels, .reset, nil))
    }
    
    func loadProjs() -> Task<Void> {
        return model.loadProjects()
    }
    
    func insertProj(at index: Int) -> KNOTProjectDetailViewModel {
        var highPriority = Double.greatestFiniteMagnitude
        var lowPriority = Double.leastNormalMagnitude
        if let projViewModels = projCellViewModelsSubject.value?.0 {
            if index < projViewModels.endIndex {
                lowPriority = projViewModels[index].model.priority
            }
            
            if index - 1 >= projViewModels.startIndex {
                highPriority = projViewModels[index - 1].model.priority
            }
        }
        let proj = KNOTProjectEntity(priority: (highPriority + lowPriority) * 0.5,
                                     name: "",
                                     flagColor: KNOTFlagColor.blue.rawValue)
        let detailModel = model.detailModel(with: proj)
        let detailViewModel = KNOTProjectDetailViewModel(model: detailModel)
        detailViewModel.updateCompleteHandler = { [weak self] _ in
            return (self?.updatePlan(at: index, insert: proj) ?? Task(()))
        }
        return detailViewModel
    }
    
    func detailViewModel(at index: Int) -> KNOTProjectDetailViewModel {
        let proj = projCellViewModelsSubject.value!.0![index].model
        let vm = KNOTProjectDetailViewModel(model: model.detailModel(with: proj))
        vm.updateCompleteHandler = { [weak self] _ in
            (self?.updatePlan(at: index, insert: nil) ?? Task(()))
        }
        return vm
    }
    
    private func updatePlan(at index: Int, insert _proj: KNOTProjectEntity? = nil) -> Task<Void> {
        var projViewModels = projCellViewModelsSubject.value?.0 ?? []
        var viewModel: KNOTProjectCellViewModel!
        if let proj = _proj {
            viewModel = KNOTProjectCellViewModel(model: proj)
            projViewModels.insert(viewModel, at: index)
            projCellViewModelsSubject.publish((projViewModels, .insert, [IndexPath(row: index, section: 0)]))
        } else {
            viewModel = projViewModels[index]
            viewModel.refresh()
            projCellViewModelsSubject.publish((projViewModels, .update, [IndexPath(row: index, section: 0)]))
        }
        return model.updateProject(viewModel.model)
    }
}

class KNOTProjectCellViewModel {
    class ColorConfig {
        let flagColors: (UIColor, UIColor)
        let flagBkColors: (UIColor, UIColor)
        let flagImageName: String
        let itemsViewBkColors: (UIColor, UIColor)
        
        init(flagColor: UInt32) {
            flagColors = (UIColor(flagColor), UIColor(flagColor))
            flagBkColors = ColorConfig.flagBkColors(byRawValue: flagColor)
            flagImageName = ColorConfig.flagImageName(byRawValue: flagColor)
            itemsViewBkColors = ColorConfig.itemsViewBkColors(byRawValue: flagColor)
        }
        
        private class func flagBkColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return (UIColor(0xFEE6E3), UIColor(0x262949))
            case KNOTFlagColor.blue.rawValue:
                return (UIColor(0xE5EBFF), UIColor(0x262949))
            case KNOTFlagColor.yellow.rawValue:
                return (UIColor(0xFFF6CF), UIColor(0x262949))
            default:
                return (UIColor(rawValue, 0.5), UIColor(0x262949))
            }
        }

        private class func itemsViewBkColors(byRawValue rawValue: UInt32) -> (UIColor, UIColor) {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return (UIColor(0xFB9F93), UIColor(0x262949, 0.5))
            case KNOTFlagColor.blue.rawValue:
                return (UIColor(0x95A7EB), UIColor(0x262949, 0.5))
            case KNOTFlagColor.yellow.rawValue:
                return (UIColor(0xFFE374), UIColor(0x262949, 0.5))
            default:
                return (UIColor(rawValue, 0.8), UIColor(0x262949, 0.5))
            }
        }

        private class func flagImageName(byRawValue rawValue: UInt32) -> String {
            switch rawValue {
            case KNOTFlagColor.red.rawValue:
                return "img_pin_r"
            case KNOTFlagColor.blue.rawValue:
                return "img_pin_b"
            case KNOTFlagColor.yellow.rawValue:
                return "img_pin_y"
            default:
                return "img_pin_b"
            }
        }
    }
    
    fileprivate let model: KNOTProjectEntity
    
    private(set) var content: String!
    private(set) var itemColors: [UIColor]!
    private(set) var colors: ColorConfig!
    var cachedContent: Any?
    
    init(model: KNOTProjectEntity) {
        self.model = model
        refresh()
    }
    
    fileprivate func refresh() {
        content = model.name
        itemColors = model.plans?.map { UIColor($0.flagColor) } ??  []
        colors = ColorConfig(flagColor: model.flagColor)
        cachedContent = nil
    }
}

