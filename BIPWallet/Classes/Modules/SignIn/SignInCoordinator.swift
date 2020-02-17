//
//  SignInCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import DeckTransition
import CardPresentationController

extension AccountManager: SignInManagerProtocol {}

class SignInCoordinator: BaseCoordinator<Void> {

  private let rootViewController: UIViewController

  init(rootViewController: UIViewController) {
    self.rootViewController = rootViewController
  }

  override func start() -> Observable<Void> {
    let controller = SignInViewController.initFromStoryboard(name: "SignIn")
    let accountManager = AccountManager()
    let viewModel = SignInViewModel(dependency: SignInViewModel.Dependency(accountManager: accountManager))
    controller.viewModel = viewModel

    viewModel.output.viewWillDismiss.subscribe(onNext: { [weak self] (_) in
      self?.rootViewController.hideBlueOverview()
      }).disposed(by: disposeBag)

//    viewModel.output.mnemonicSaved.subscribe(onNext: { [weak self] (_) in
//      let walletCoordinator = WalletCoordinator(rootViewController: rootViewController)
//      self?.coordinate(to: walletCoordinator)
//      }).disposed(by: disposeBag)

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 0.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = false

    rootViewController.showBlurOverview()

    rootViewController.presentCard(ClearBarNavigationController(rootViewController: controller),
                                   configuration: cardConfig,
                                   animated: true)

    return viewModel.output.mnemonicSaved.asObservable()
  }

}
