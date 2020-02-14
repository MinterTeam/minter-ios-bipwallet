//
//  WelcomeCoordinatorAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import Swinject

struct WelcomeCoordinatorAssembly: Assembly {

  func assemble(container: Container) {
    container.register(WelcomeCoordinator.self) { (resolver, parentAssembler: Assembler) in
      let assembler = Assembler(
          [
              WelcomeModuleAssembly()
          ],
          parent: parentAssembler
      )
      let router = NavigationRouter(rootController: UINavigationController())
      let coordinator = WelcomeCoordinatorImpl(assembler: assembler, router: router)
      return coordinator
    }
  }
}
