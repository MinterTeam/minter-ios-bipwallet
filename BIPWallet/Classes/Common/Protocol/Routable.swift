//
//  Routable.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol Routable: Presentable {

  func setRootModule(_ module: Presentable?, animated: Bool)
  func push(_ module: Presentable?, animated: Bool)
  func popModule(animated: Bool)
  func present(_ module: Presentable?, animated: Bool)
  func dismissModule(animated: Bool, completion: (() -> Void)?)

}
