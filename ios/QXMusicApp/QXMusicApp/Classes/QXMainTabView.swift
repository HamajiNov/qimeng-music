//
//  QXMainTabController.swift
//  QXMusicApp
//

import UIKit

/// 主 Tab 控制器
final class QXMainTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let library = UINavigationController(rootViewController: QXLibraryViewController())
        library.tabBarItem = UITabBarItem(title: "乐谱库", image: UIImage(systemName: "music.note.list"), tag: 0)

        let scan = UINavigationController(rootViewController: QXScanViewController())
        scan.tabBarItem = UITabBarItem(title: "拍照识别", image: UIImage(systemName: "camera.viewfinder"), tag: 1)

        let profile = UINavigationController(rootViewController: QXProfileViewController())
        profile.tabBarItem = UITabBarItem(title: "我的", image: UIImage(systemName: "person.circle"), tag: 2)

        viewControllers = [library, scan, profile]
    }
}
