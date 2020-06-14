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
import SafariServices

class TransactionCoordinator: BaseCoordinator<Void> {

  var rootViewController: UIViewController
  var transaction: MinterExplorer.Transaction
  var recipientInfoService: RecipientInfoService
  let address: String

  init(transaction: MinterExplorer.Transaction,
       address: String,
       rootViewController: UIViewController,
       recipientInfoService: RecipientInfoService) {
    self.rootViewController = rootViewController
    self.transaction = transaction
    self.address = address
    self.recipientInfoService = recipientInfoService

    super.init()
  }

  override func start() -> Observable<Void> {
    let dependency = TransactionViewModel.Dependency(recipientInfoService: recipientInfoService)
    let viewModel = TransactionViewModel(transaction: self.transaction,
                                         address: self.address,
                                         dependency: dependency)

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

    viewModel.output.didTapShare.debug().map({ [weak self] (_) -> URL? in
      guard let transaction = self?.transaction else { return nil }
      return self?.explorerURL(transaction: transaction)
    }).filter{$0 != nil}.map{$0!}.subscribe(onNext: { [weak controller] (url) in
      let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      controller?.present(ac, animated: true)
    }).disposed(by: disposeBag)

    viewModel.output.showExplorer.map({ [weak self] (hash) -> URL? in
      guard let transaction = self?.transaction else { return nil }
      return self?.explorerURL(transaction: transaction)//URL(string: MinterExplorerBaseURL! + "/transactions/" + (hash ?? ""))
    }).subscribe(onNext: { [weak controller] (url) in
      guard let url = url else { return }
      let safari = SFSafariViewController(url: url)
      controller?.present(safari, animated: true) {}
    }).disposed(by: disposeBag)

    return controller.rx.deallocated
  }

  func explorerURL(transaction: MinterExplorer.Transaction) -> URL? {
    if let hash = transaction.hash {
      return URL(string: MinterExplorerBaseURL! + "/transactions/" + hash)
    }
    return nil
  }

}
