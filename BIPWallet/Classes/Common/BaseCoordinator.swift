//
//  BaseCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import Swinject

open class BaseCoordinator: Coordinator {

  var childCoordinators: [Coordinator] = []
  let router: Routable
  let assembler: Assembler

  init(assembler: Assembler, router: Routable) {
    self.assembler = assembler
    self.router = router
  }

  open func start(with option: DeepLinkOption?) {

  }

  open func start() {}

  func addDependency(_ coordinator: Coordinator) {
    guard !childCoordinators.contains(where: { $0 === coordinator }) else { return }
    childCoordinators.append(coordinator)
  }

  func removeDependency(_ coordinator: Coordinator?) {
    guard let indexToRemove = childCoordinators
      .firstIndex(where: { $0 === coordinator })
          else { return }
    
    childCoordinators.remove(at: indexToRemove)
  }

  func removeAllDependencies() {
    childCoordinators.removeAll()
  }

}
