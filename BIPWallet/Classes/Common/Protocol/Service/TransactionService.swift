//
//  TransactionService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterExplorer

enum TransactionServiceFilter: String {
  case incoming = "incoming"
  case outgoing = "outcoming"
}

enum TransactionServiceError: Error {
  case empty
  case noTransaction
  case custom(error: Error)
}

protocol TransactionService {
  func transactions(address: String, filter: TransactionServiceFilter?, page: Int) -> Observable<[MinterExplorer.Transaction]>
  func transaction(hash: String) -> Observable<MinterExplorer.Transaction?>
}
