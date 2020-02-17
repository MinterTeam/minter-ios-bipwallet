//
//  Controller.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol Controller: class {

  var viewModel: ViewModelType! { get set }

  associatedtype ViewModelType: ViewModel
  /// Configurates controller with specified ViewModelProtocol subclass
  ///
  /// - Parameter viewModel: ViewModel subclass instance to configure with
  func configure(with viewModel: ViewModelType)
}
