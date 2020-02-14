//
//  CreateWalletAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import Swinject

struct CreateWalletModuleAssembly: Assembly {

  func assemble(container: Container) {
    container.register(CreateWalletCoordinator.self) { (resolver, parentAssembler: Assembler) in
      let assembler = Assembler(
          [
              CreateWalletModuleAssembly()
          ],
          parent: parentAssembler
      )
      let router = NavigationRouter(rootController: UINavigationController())
      let coordinator = CreateWalletCoordinatorImpl(assembler: assembler, router: router)
      return coordinator
    }
  }
}
