//
//  GetCoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class GetCoinsCoordinator: BaseCoordinator<Void> {

  private var сontroller = GetCoinsViewController.initFromStoryboard(name: "GetCoins")

  init(viewController: inout UIViewController?) {
    viewController = сontroller
  }

  override func start() -> Observable<Void> {
    return Observable.never()
  }

}
