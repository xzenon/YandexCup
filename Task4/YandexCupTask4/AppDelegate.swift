//
//  AppDelegate.swift
//  YandexCupTask4
//
//  Created by Xenon on 17.10.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let navigationController = UINavigationController(rootViewController: ViewController())
        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()
        
        return true
    }
}
