//
//  DeepLinkOption.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

public protocol DeepLinkOption {

  static func build(with userActivity: NSUserActivity) -> DeepLinkOption?
  static func build(with dict: [String: AnyObject]?) -> DeepLinkOption?
}
