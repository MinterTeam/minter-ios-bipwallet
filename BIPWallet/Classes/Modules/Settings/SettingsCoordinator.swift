//
//  SettingsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SettingsCoordinator: BaseCoordinator<Void> {

  private let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController

    super.init()
  }

  override func start() -> Observable<Void> {
    let dependency = SettingsViewModel.Dependency()
    let viewModel = SettingsViewModel(dependency: dependency)
    let controller = SettingsViewController.initFromStoryboard(name: "Settings")
    controller.viewModel = viewModel

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}
