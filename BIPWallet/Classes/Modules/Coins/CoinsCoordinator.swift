//
//  CoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState

class CoinsCoordinator: BaseCoordinator<Void> {

  var didScrollToPoint: Observable<CGPoint>?
//  var didChangeInset = PublishSubject<CGFloat>()

  var viewController: CoinsViewController?

  override func start() -> Observable<Void> {
    let controller = CoinsViewController.initFromStoryboard(name: "Coins")

    let balanceService = ExplorerBalanceService()
    let localAuthService = LocalStorageAuthService()
    guard let account = localAuthService.selectedAccount() else {
      return Observable.empty()
    }

    let viewModel = CoinsViewModel(address: "Mx" + account.address, dependency: CoinsViewModel.Dependency(balanceService: balanceService))
//    coins.asDriver(onErrorJustReturn: [:]).drive(viewModel.input.coins).disposed(by: disposeBag)

    controller.viewModel = viewModel
    self.viewController = controller

    self.didScrollToPoint = controller.rx.viewDidLoad.flatMap({ (_) -> Observable<CGPoint> in
      return controller.tableView.rx.didScroll.map { (_) -> CGPoint in
        return controller.tableView.contentOffset
      }
    })

//    didChangeInset.subscribe(onNext: { [weak controller] (val) in
//      controller?.tableView.contentOffset = CGPoint(x: 0, y: val)//UIEdgeInsets(top: val, left: 0, bottom: 0, right: 0)
//    }).disposed(by: disposeBag)

    return Observable.never()
  }

}
