//
//  ShareCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

class ShareCoordinator: BaseCoordinator<Void> {
  
  let rootViewController: UIViewController
  let account: AccountItem
  
  init(rootViewController: UIViewController, account: AccountItem) {
    self.rootViewController = rootViewController
    self.account = account
  }

  override func start() -> Observable<Void> {

    let dependency = ShareViewModel.Dependency()
    let viewModel = ShareViewModel(account: self.account, dependency: dependency)
    let controller = ShareViewController.initFromStoryboard(name: "Share")
    controller.viewModel = viewModel

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 20.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

    //Seem to be a bug, but without "main.async" it delays
    DispatchQueue.main.async { [weak self] in
      self?.rootViewController.presentCard(controller,
                                           configuration: cardConfig,
                                           animated: true)
    }

    viewModel.output.didTapShare.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      let ac = UIActivityViewController(activityItems: [self.account.address], applicationActivities: nil)
      controller.present(ac, animated: true)
    }).disposed(by: disposeBag)

    return Observable.never()
  }

}
