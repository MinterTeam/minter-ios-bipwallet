//
//  BalanceView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19.11.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class BalanceView: UIView {

  @IBOutlet weak var balanceTitle: UILabel!
  @IBOutlet weak var address: UILabel!
  @IBOutlet weak var availableBalance: UILabel!
  @IBOutlet weak var delegatedBalanceTitle: UILabel!
  @IBOutlet weak var delegatedBalance: UILabel! {
    didSet {
      delegatedBalance.font = UIFont.semiBoldFont(of: 16.0)
    }
  }
  @IBOutlet weak var delegatedBalanceButton: UIButton!

}
