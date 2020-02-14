//
//  BIPWelcomeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit

protocol WelcomeCoordinator: Coordinator {
  typealias Completion = (DeepLinkOption?) -> Void

  var onFinish: Completion? { get set }
}

class WelcomeCoordinatorImpl: BaseCoordinator, WelcomeCoordinator {

  override func start() {
    var module = assembler.resolver.resolve(WelcomeModule.self)
    module?.onFinish = { [weak self] in
      self?.onFinish?(nil)
    }
    router.push(module, animated: false)
  }

  override func start(with option: DeepLinkOption?) {
    var module = assembler.resolver.resolve(WelcomeModule.self)
    module?.onFinish = { [weak self] in
      self?.onFinish?(option)
    }
    router.push(module, animated: false)
  }

  var onFinish: Completion?

}
