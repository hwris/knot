//
//  ViewController.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var model: KNOTProjectModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = KNOTProjectModelImpl()
        
        let project = KNOTProjectEntity(createDate: Date(), name: "Test1241412412412", labelColor: 0)
        
        model.add(project: project) { (itemModel, error) in
            print(itemModel, error)
            self.model.loadItems { (error) in
                print(error ?? "success")
                self.model.delete(project: KNOTProjectEntity(createDate: Date(timeIntervalSince1970: 1585404470409 / 1000.0), name: "Test1241412412412", labelColor: 0)) { (error) in
                    print(error ?? "success")
                }
            }
        }
    }
}

