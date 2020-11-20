//
//  URL+ValidatorAvatar.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

extension URL {

  static func validatorURL(with publicKey: String) -> URL {
    let str = "https://explorer-static.minter.network/validators/\(publicKey).png"
    return URL(string: str)!
  }

}
