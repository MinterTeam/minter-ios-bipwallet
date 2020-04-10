//
//  AddWalletCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

enum AddWalletCoordinatorResult {
  case added(AccountItem)
  case cancel
}

class AddWalletCoordinator: BaseCoordinator<AddWalletCoordinatorResult> {

  private let rootViewController: UIViewController
  private let authService: AuthService

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
  }

  override func start() -> Observable<AddWalletCoordinatorResult> {
    let dependency = AddWalletViewModel.Dependency(authService: authService)
    let viewModel = AddWalletViewModel(dependency: dependency)
    let controller = AddWalletViewController.initFromStoryboard(name: "AddWallet")
    controller.viewModel = viewModel

    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.tabBarController?.present(controller, animated: true)

    viewModel.output.accountAdded.subscribe(onNext: { (_) in
      UIView.animate(withDuration: 0.5) {
        controller.updateBlurView(percentage: 0.0)
      }
      controller.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)

    return Observable.merge(viewModel.output.accountAdded.map({ (account) -> AddWalletCoordinatorResult in
      return .added(account)
    }), viewModel.output.viewDidDisappear.map { _ in .cancel }).take(1)
  }

}
