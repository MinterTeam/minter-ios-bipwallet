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

class SignInCoordinator: BaseCoordinator<Void> {

  private let rootViewController: UIViewController
  private let authService: AuthService

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
  }

  override func start() -> Observable<Void> {
    let controller = SignInViewController.initFromStoryboard(name: "SignIn")
    let viewModel = SignInViewModel(dependency: SignInViewModel.Dependency(authService: authService))
    controller.viewModel = viewModel

    viewModel.output.viewDidDisappear.subscribe(onNext: { [weak self] (_) in
      self?.rootViewController.hideBlueOverview()
    }).disposed(by: disposeBag)

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

    return Observable.merge(viewModel.output.mnemonicSaved, viewModel.output.viewDidDisappear.map { _ in Void() })
  }

}
