//
//  Presentable.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

protocol Presentable {
  var toPresent: UIViewController? { get }
}

extension UIViewController: Presentable {

  var toPresent: UIViewController? {
    return self
  }
}
