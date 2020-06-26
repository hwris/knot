//
//  AppDelegate.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/22.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let homeVC = window!.rootViewController as! KNOTHomeViewController
        homeVC.viewModel = KNOTViewModel(model: KNOTModelImpl())
        return true
    }
}

