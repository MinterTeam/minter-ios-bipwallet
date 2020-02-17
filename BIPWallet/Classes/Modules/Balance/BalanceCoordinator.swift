//
//  BalanceCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class BalanceCoordinator: BaseCoordinator<Void> {

  private let window: UIWindow

  init(window: UIWindow) {
    self.window = window
  }

  override func start() -> Observable<Void> {
    let controller = BalanceViewController()
    controller.viewModel = BalanceViewModel(dependency: BalanceViewModel.Dependency())

    let navigationController = UINavigationController(rootViewController: controller)
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
    return Observable.never()
  }

}
