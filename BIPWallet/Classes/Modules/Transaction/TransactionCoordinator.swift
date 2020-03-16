//
//  TransactionCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import MinterCore
import MinterExplorer
import CardPresentationController

class TransactionCoordinator: BaseCoordinator<Void> {

  var rootViewController: UIViewController

  init(transaction: MinterExplorer.Transaction, rootViewController: UIViewController) {
    self.rootViewController = rootViewController

    super.init()
  }

  override func start() -> Observable<Void> {
    let viewModel = TransactionViewModel(dependency: TransactionViewModel.Dependency())
    let viewController = TransactionViewController.initFromStoryboard(name: "Transaction")
    viewController.viewModel = viewModel

//    CardPresentationController.useSystemPresentationOniOS13 = true
//    rootViewController.presentCard(viewController, configuration: nil, animated: true) {}
    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 20.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

    rootViewController.presentCard(ClearBarNavigationController(rootViewController: viewController),
                                   configuration: cardConfig,
                                   animated: true)

    return viewModel.output.didDismiss.asObservable()
  }

}
