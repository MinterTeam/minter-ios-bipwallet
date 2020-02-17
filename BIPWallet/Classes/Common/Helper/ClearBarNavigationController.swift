//
//  ClearBarNavigationController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class ClearBarNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationBar.setBackgroundImage(nil, for: .default)
    self.navigationBar.isHidden = true
  }
  
}
