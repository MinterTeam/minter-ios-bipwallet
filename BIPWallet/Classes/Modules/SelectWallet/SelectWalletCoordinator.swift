//
//  SelectWalletCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum SelectWalletCoordinationResult {
  case wallet(String)
  case cancel
}

class SelectWalletCoordinator: BaseCoordinator<SelectWalletCoordinationResult> {

  private let rootViewController: UIViewController

  private let authService: AuthService

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
  }

  override func start() -> Observable<SelectWalletCoordinationResult> {
    let viewModel = SelectWalletViewModel(dependency: SelectWalletViewModel.Dependency(authService: authService))
    let viewController = SelectWalletViewController.initFromStoryboard(name: "SelectWallet")
    viewController.viewModel = viewModel

    let didCancel = viewModel.output.didCancel.map { _ in SelectWalletCoordinationResult.cancel}
    let didSelect = viewModel.output.didSelect.map { _ in SelectWalletCoordinationResult.wallet("")}

    viewController.modalPresentationStyle = .overCurrentContext
    viewController.modalTransitionStyle = .crossDissolve

//    rootViewController.willMove(toParent: viewController)
    rootViewController.addChild(viewController)
//    viewController.view.frame = CGRect(x: 0, y: 0, width: 272, height: 0)
    viewController.view.isUserInteractionEnabled = false
    rootViewController.view.addSubview(viewController.view)
    viewController.didMove(toParent: rootViewController)
//    rootViewController.present(viewController, animated: true, completion: nil)
    viewController.view.layer.zPosition = 999
    return Observable.merge(didCancel, didSelect).take(1)
  }

}
