//
//  WhiteNavigationController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class WhiteNavigationController: UINavigationController {

  override func loadView() {
    super.loadView()

    self.navigationBar.shadowImage = UIImage(named: "NavigationBarShadowImage")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
