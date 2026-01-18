//
//  AppDelegate.swift
//  ChiCheck
//
//  Created by Benjamin Friesen on 2026-01-17.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Create the window explicitly
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 2. Create the Home Screen (See code for HomeViewController below)
        let homeVC = HomeViewController()
        
        // 3. Put the Home Screen inside a Navigation Controller
        // This enables the "Push" and "Pop" (Back button) functionality
        let nav = UINavigationController(rootViewController: homeVC)
        
        // 4. Set the Navigation Controller as the root
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }

    // MARK: - UISceneSession Lifecycle (Standard boilerplate)

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
}
