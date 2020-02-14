//
//  LoginAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import Swinject

struct LoginModuleAssembly: Assembly {

  func assemble(container: Container) {
    container.register(LoginCoordinator.self) { (resolver, parentAssembler: Assembler) in
      let assembler = Assembler(
          [
              LoginModuleAssembly()
          ],
          parent: parentAssembler
      )
      let router = NavigationRouter(rootController: UINavigationController())
      let coordinator = LoginCoordinatorImpl(assembler: assembler, router: router)
      return coordinator
    }
  }
}
