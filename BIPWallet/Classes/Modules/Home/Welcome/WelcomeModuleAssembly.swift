//
//  BIPWelcomeAssembly.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import Swinject

struct WelcomeModuleAssembly: Assembly {

  func assemble(container: Container) {
    container.register(WelcomeModule.self) { (resolver) in
      let controller = WelcomeViewController()
      let viewModel = WelcomeViewModel(dependency: WelcomeViewModel.Dependency())

      controller.viewModel = viewModel
      return controller
    }
  }
}
