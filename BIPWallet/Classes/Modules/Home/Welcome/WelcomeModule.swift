//
//  BIPWelcomeModule.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit

protocol WelcomeModule: Presentable {

  typealias Completion = () -> Void
  var onFinish: Completion? { get set }
}
