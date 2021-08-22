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
            let projs = new?.0 ?? []
            self?.publishProjs(projs)
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
        model.loadProjects()
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
        let detailModel = model.projectDetailModel(with: proj)
        return KNOTProjectDetailViewModel(model: detailModel)
    }
    
    func detailViewModel(at index: Int) -> KNOTProjectDetailViewModel {
        let proj = projCellViewModelsSubject.value!.0![index].model
        return KNOTProjectDetailViewModel(model: model.projectDetailModel(with: proj))
    }
    
    func plansViewModel(at index: Int) -> KNOTProjectPlanViewModel {
        let projVM = projCellViewModelsSubject.value!.0![index]
        let proj = projVM.model
        let vm = KNOTProjectPlanViewModel(model: model.projectPlansModel(with: proj))
        vm.title = projVM.content
        return vm
    }
    
    func moreViewModel(at index: Int) -> KNOTProjectMoreViewModel {
        let proj = projCellViewModelsSubject.value!.0![index].model
        return KNOTProjectMoreViewModel(model: model.projectMoreModel(with: proj))
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
    
    let content: String
    let itemColors: [UIColor]
    let colors: ColorConfig
    var cachedContent: Any?
    
    init(model: KNOTProjectEntity) {
        self.model = model
        content = model.name
        itemColors = model.plans?.map { UIColor($0.flagColor) } ??  []
        colors = ColorConfig(flagColor: model.flagColor)
    }
}
