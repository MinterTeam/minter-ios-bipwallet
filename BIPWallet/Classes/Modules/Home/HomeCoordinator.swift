//
//  HomeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 13.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol HomeCoordinator {
  func showLogin()
}

final class HomeCoordinatorImpl: BaseCoordinator, HomeCoordinator {

  internal func showLogin() {
    var module = assembler.resolver.resolve(LoginModule.self)
    module?.onFinish = { [weak self] in
      
    }
    router.push(module, animated: false)
  }

}
