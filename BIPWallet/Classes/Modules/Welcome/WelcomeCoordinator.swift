//
//  WelcomeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices

class WelcomeCoordinator: BaseCoordinator<Void> {

  private let window: UIWindow

  init(window: UIWindow) {
    self.window = window
  }

  override func start() -> Observable<Void> {
    let controller = WelcomeViewController.initFromStoryboard(name: "Welcome")
    let viewModel = WelcomeViewModel(dependency: WelcomeViewModel.Dependency())
    controller.viewModel = viewModel

    viewModel.output.showHelp.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      `self`.showHelp(in: controller)
    }).disposed(by: disposeBag)

    let showSignIn = viewModel.output.showSignIn.flatMap { [weak self] (_) -> Observable<Void> in
      guard let `self` = self else { return .empty() }
      return `self`.showSignIn(in: controller)
    }

    let showCreateWallet = viewModel.output.showCreateWallet.flatMap { [weak self] (_) -> Observable<Void> in
      guard let `self` = self else { return .empty() }
      return `self`.showCreateWallet(in: controller)
    }

    window.rootViewController = controller
    window.makeKeyAndVisible()
    return Observable.merge(showSignIn, showCreateWallet)
  }

  func showHelp(in viewController: UIViewController) {
    guard let url = URL(string: Configuration().environment.helpURL) else {
      return
    }
    let safariViewController = SFSafariViewController(url: url)
    viewController.present(safariViewController, animated: true) {
      
    }
  }

  func showSignIn(in viewController: UIViewController) -> Observable<Void> {
    let coordinator = SignInCoordinator(rootViewController: viewController)
    return coordinate(to: coordinator)
  }

  func showCreateWallet(in viewController: UIViewController) -> Observable<Void> {
    let coordinator = SignInCoordinator(rootViewController: viewController)
    return coordinate(to: coordinator)
  }

}
