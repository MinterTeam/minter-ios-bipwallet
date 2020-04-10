//
//  SelectWalletCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture

enum SelectWalletCoordinationResult {
  case wallet(String)
  case edit(AccountItem)
  case cancel
  case addWallet
}

class SelectWalletCoordinator: BaseCoordinator<SelectWalletCoordinationResult> {

  private let rootViewController: UIViewController
  private let authService: AuthService

  let viewController: SelectWalletViewController

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
    self.viewController = SelectWalletViewController.initFromStoryboard(name: "SelectWallet")
  }

  private let selectWalletResult = PublishSubject<SelectWalletCoordinationResult>()

  override func start() -> Observable<SelectWalletCoordinationResult> {
    let viewModel = SelectWalletViewModel(dependency: SelectWalletViewModel.Dependency(authService: authService))
    viewController.viewModel = viewModel

    let didCancel = viewModel.output.didCancel.map { _ in SelectWalletCoordinationResult.cancel }
    let didSelect = viewModel.output.didSelect.map { address in SelectWalletCoordinationResult.wallet(address) }
    let addWallet = viewModel.output.showAdd.map { address in SelectWalletCoordinationResult.addWallet }
    let editTitle = viewModel.output.showEdit.map { account in SelectWalletCoordinationResult.edit(account) }
    let forceCancel = PublishSubject<Void>()

    viewController.modalPresentationStyle = .overCurrentContext
    viewController.modalTransitionStyle = .crossDissolve

    rootViewController.present(viewController, animated: true) { [weak self] in
      guard let `self` = self else { return }
      //Configure VC's view to pass touches to underneath views
      //Touchable should be only tableView and it's wrapper
      (self.viewController.view as? PassthroughView)?.passView = self.rootViewController.view
      //And dismiss VC on first outside touch
      (self.viewController.view as? PassthroughView)?.delegate = self
    }

    let resultObservable = Observable.merge(editTitle, addWallet, didCancel, didSelect, forceCancel.map { _ in SelectWalletCoordinationResult.cancel })

    resultObservable.do(onNext: { [weak self] (result) in
      self?.viewController.dismiss(animated: true, completion: nil)
    }).subscribe(selectWalletResult).disposed(by: disposeBag)

    return selectWalletResult.take(1)
  }

}

extension SelectWalletCoordinator: PassthroughViewDelegate {

  func willPassHitWith(point: CGPoint, event: UIEvent?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
      self?.viewController.dismiss(animated: false, completion: {
        self?.selectWalletResult.onNext(.cancel)
      })
    })
  }
}
