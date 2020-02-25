//
//  SettingsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SettingsCoordinator: BaseCoordinator<UIViewController> {

  private let tabbarItem: UITabBarItem?

  init(tabbarItem: UITabBarItem) {
    self.tabbarItem = tabbarItem

    super.init()
  }

  override func start() -> Observable<UIViewController> {
    let controller = UIViewController()
    controller.tabBarItem = self.tabbarItem
    controller.view.backgroundColor = .blue

    return Observable.just(controller)
  }

}
