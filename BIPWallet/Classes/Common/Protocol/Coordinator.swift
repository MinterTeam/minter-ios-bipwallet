//
//  Coordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol Coordinator: class {

  var router: Routable { get }

  func start()

  func start(with option: DeepLinkOption?)
}
