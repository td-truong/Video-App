//
//  AppDelegate.swift
//  VideoApp
//
//  Created by Duy Truong on 05/07/2021.
//

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: .init(origin: .zero, size: UIScreen.main.bounds.size))
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }


}

