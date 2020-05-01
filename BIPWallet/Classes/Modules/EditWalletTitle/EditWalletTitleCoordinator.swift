//
//  EditWalletTitleCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 09/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum EditWalletTitleCoordinatorResult {
  case changedTitle(account: AccountItem)
  case removed
  case cancel
}

class EditWalletTitleCoordinator: BaseCoordinator<EditWalletTitleCoordinatorResult> {
  
  var rootViewController: UIViewController
  var authService: AuthService
  var account: AccountItem

  init(rootViewController: UIViewController, authService: AuthService, account: AccountItem) {
    self.rootViewController = rootViewController
    self.authService = authService
    self.account = account
  }

  override func start() -> Observable<EditWalletTitleCoordinatorResult> {
    let dependency = EditWalletTitleViewModel.Dependency(authService: authService)
    let viewModel = EditWalletTitleViewModel(account: account,
                                             isLastAccount: authService.accounts().count == 1,
                                             dependency: dependency)

    let controller = EditWalletTitleViewController.initFromStoryboard(name: "EditWalletTitle")
    controller.viewModel = viewModel

    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.tabBarController?.present(controller, animated: true)

    Observable.of(viewModel.output.didChange, viewModel.output.didRemove).merge()
      .subscribe(onNext: { (_) in
        UIView.animate(withDuration: 0.5) {
          controller.updateBlurView(percentage: 0.0)
        }
        controller.dismiss(animated: true, completion: nil)
      }).disposed(by: disposeBag)

    let changedResult = viewModel.output.didChange.map { _ in
      return EditWalletTitleCoordinatorResult.changedTitle(account: self.account)
    }

    let removedResult = viewModel.output.didRemove.map { _ -> EditWalletTitleCoordinatorResult in
      return .removed
    }

    return Observable.merge(removedResult, changedResult, controller.rx.viewDidDisappear.map { _ in .cancel }).take(1)
  }

}
