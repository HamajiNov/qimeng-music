//
//  QXMusicApp.swift
//  QXMusicApp
//

import UIKit
import LXProtocol

@main
final class QXAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = UIApplication.runOnce // 触发 LXProtocol 自发现

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = QXMainTabController()
        window?.makeKeyAndVisible()
        return true
    }
}
