//
//  AppCoordinatorAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Swinject

struct AppCoordinatorAssembly: Assembly {

  func assemble(container: Container) {
    container.register(AppCoordinator.self) { (resolver, parentAssembler: Assembler, window: UIWindow?) in
      let assembler = Assembler([WelcomeCoordinatorAssembly(),
                                 WelcomeModuleAssembly()
          ],
          parent: parentAssembler
      )
      let router = AppRouter(window: window)
      let coordinator = AppCoordinatorImpl(assembler: assembler, router: router)
      return coordinator
    }
  }
}
