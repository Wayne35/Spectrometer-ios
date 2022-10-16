//
//  TabbarVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/3/3.
//

import UIKit

class TabbarVC: UITabBarController {

    var image: UIImage?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: Notification.Name("ToDo"), object: self.image)
    }
}
