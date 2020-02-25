//
//  SendCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendCoordinator: BaseCoordinator<Void> {

  private let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController

    super.init()
  }

  override func start() -> Observable<Void> {
    let controller = UIViewController()
    controller.view.backgroundColor = .black

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}
