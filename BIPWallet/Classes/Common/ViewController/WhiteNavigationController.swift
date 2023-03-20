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
    
    self.navigationController?.navigationBar.barTintColor = .mainWhiteColor()
    if #available(iOS 15, *) {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = .white
      self.navigationBar.standardAppearance = appearance;
      self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
