//
//  WalletRemoveConfirmationViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 06/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class WalletRemoveConfirmationViewModel: BaseViewModel, ViewModel {

  // MARK: -

  let account: AccountItem

  private let didConfirm = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: WalletRemoveConfirmationViewModel.Input!
  var output: WalletRemoveConfirmationViewModel.Output!
  var dependency: WalletRemoveConfirmationViewModel.Dependency!

  struct Input {
    var didTapConfirmButton: AnyObserver<Void>
  }

  struct Output {
    var didConfirm: Observable<Void>
    var text: Observable<NSAttributedString?>
  }

  struct Dependency {

  }

  init(account: AccountItem, dependency: Dependency) {
    self.account = account

    self.dependency = dependency

    super.init()

    self.input = Input(didTapConfirmButton: didConfirm.asObserver()
    )

    self.output = Output(didConfirm: didConfirm.asObservable(),
                         text: Observable.just(self.text())
    )
  }

  // MARK: -

  func text() -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Are you sure, you want to remove ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    
    string.append(NSAttributedString(string: account.address,
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 14.0)]))
    string.append(NSAttributedString(string: " from this application?".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    
    string.append(NSAttributedString(string: "Attention! ",
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 14.0)]))
    string.append(NSAttributedString(string: "Attention! The wallet will not be deleted from blockchain. You’ll be able to readd it later with the saved seed-phrase.".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    

    return string
  }

}
