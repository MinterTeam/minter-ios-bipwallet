//
//  BalanceAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 13/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import Swinject

struct BalanceModuleAssembly: Assembly {

  func assemble(container: Container) {
    container.register(BalanceCoordinator.self) { (resolver, parentAssembler: Assembler) in
      let assembler = Assembler(
          [
              BalanceModuleAssembly()
          ],
          parent: parentAssembler
      )
      let router = NavigationRouter(rootController: UINavigationController())
      let coordinator = WelcomeCoordinatorImpl(assembler: assembler, router: router)
      return coordinator
    }
  }
}
