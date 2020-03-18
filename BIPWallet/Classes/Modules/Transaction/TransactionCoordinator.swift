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
  var transaction: MinterExplorer.Transaction

  init(transaction: MinterExplorer.Transaction, rootViewController: UIViewController) {
    self.rootViewController = rootViewController
    self.transaction = transaction

    super.init()
  }

  override func start() -> Observable<Void> {
    let viewModel = TransactionViewModel(transaction: self.transaction,
                                         dependency: TransactionViewModel.Dependency())

    let viewController = TransactionViewController.initFromStoryboard(name: "Transaction")
    viewController.viewModel = viewModel

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 20.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

    let controller = ClearBarNavigationController(rootViewController: viewController)

    //Seem to be a bug, but without "main.async" it delays
    DispatchQueue.main.async { [weak self] in
      self?.rootViewController.presentCard(controller,
                                           configuration: cardConfig,
                                           animated: true)
    }

    return viewModel.output.didDismiss.asObservable()
  }

}
