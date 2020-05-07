//
//  WalletRemoveConfirmationCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 06/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum WalletRemoveConfirmationCoordinatorResult {
  case confirm(account: AccountItem)
  case cancel
}

class WalletRemoveConfirmationCoordinator: BaseCoordinator<WalletRemoveConfirmationCoordinatorResult> {

  let rootViewController: UIViewController
  let account: AccountItem

  init(rootViewController: UIViewController, account: AccountItem) {
    self.rootViewController = rootViewController
    self.account = account
  }

  override func start() -> Observable<WalletRemoveConfirmationCoordinatorResult> {
    let viewModel = WalletRemoveConfirmationViewModel(account: account, dependency: WalletRemoveConfirmationViewModel.Dependency())
    let controller = WalletRemoveConfirmationViewController.initFromStoryboard(name: "WalletRemoveConfirmation")
    controller.viewModel = viewModel
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.present(controller, animated: true, completion: nil)

    viewModel.output.didConfirm.subscribe(onNext: { (_) in
      controller.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)

    let resultObservable = Observable.of(
      controller.rx.viewDidDisappear.map {_ in WalletRemoveConfirmationCoordinatorResult.cancel },
      viewModel.output.didConfirm.map { item in WalletRemoveConfirmationCoordinatorResult.confirm(account: self.account) }
    ).merge()

    return resultObservable.take(1)
  }

}
