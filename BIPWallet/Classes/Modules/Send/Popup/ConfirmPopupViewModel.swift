//
//  ConfirmPopupViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ConfirmPopupViewModel: PopupViewModel, ViewModel {

	// MARK: - ViewModelProtocol

	struct Input {
		var didTapAction: AnyObserver<Void>
		var didTapCancel: AnyObserver<Void>
		var activityIndicator: AnyObserver<Bool>
    var didTapWallet: AnyObserver<Void>
    var didSelectWallet: AnyObserver<[Int: String]>
    var viewWillAppear: AnyObserver<Void>
	}

	struct Output {
		var isActivityIndicatorAnimating: Observable<Bool>
		var description: String?
		var didTapActionButton: Observable<AccountItem?>
		var didTapCancel: Observable<Void>
    var showWallets: Observable<[[String]]>
    var selectedWallet: Observable<String?>
    var activeButtonTitle: Observable<String?>
	}

	struct Dependency {
    var authService: AuthService
  }

	var input: ConfirmPopupViewModel.Input!
  
	var output: ConfirmPopupViewModel.Output!

	var dependency: ConfirmPopupViewModel.Dependency!

	// MARK: -

	var desc: String?
	var buttonTitle: String?
	var cancelTitle: String?

	// MARK: -

	private let didTapActionSubject = PublishSubject<Void>()
	private let didTapCancelSubject = PublishSubject<Void>()
	private let activityIndicatorSubject = PublishSubject<Bool>()
  private let didTapWallet = PublishSubject<Void>()
  private let didSelectWallet = BehaviorSubject<[Int: String]>(value: [:])
  private let selectedWallet = PublishSubject<String?>()
  private let viewWillAppear = PublishSubject<Void>()
  private let activeButtonTitle = PublishSubject<String?>()

  init(desc: String?, buttonTitle: String? = nil, cancelTitle: String? = nil, dependency: Dependency) {
		super.init()

    self.dependency = dependency

		input = Input(didTapAction: didTapActionSubject.asObserver(),
									didTapCancel: didTapCancelSubject.asObserver(),
                  activityIndicator: activityIndicatorSubject.asObserver(),
                  didTapWallet: didTapWallet.asObserver(),
                  didSelectWallet: didSelectWallet.asObserver(),
                  viewWillAppear: viewWillAppear.asObserver()
    )

		output = Output(isActivityIndicatorAnimating: activityIndicatorSubject.asObservable(),
										description: desc,
                    didTapActionButton: didTapActionSubject.withLatestFrom(selectedWallet).map { self.itemFor(title: $0 ?? "") }.asObservable(),
                    didTapCancel: didTapCancelSubject.asObservable(),
                    showWallets: showWalletsObservable(),
                    selectedWallet: selectedWallet.asObservable(),
                    activeButtonTitle: activityIndicatorSubject.map { $0 ? "" : "Proceed".localized() }
    )

    bind()
	}

  func bind() {
    didSelectWallet.subscribe(onNext: { [weak self] (selection) in
      guard let `self` = self else { return }
      if let firstValue = selection.first?.value {
        if let account = self.dependency.authService.accounts().filter { (item) -> Bool in
          return firstValue == self.pickerTitle(from: item)
        }.first {
          self.selectedWallet.onNext(firstValue)
        }
      }
    }).disposed(by: disposeBag)

    viewWillAppear.subscribe(onNext: { (_) in
      if let firstWallet = self.dependency.authService.accounts().first {
        self.selectedWallet.onNext(self.pickerTitle(from: firstWallet))
      }
    }).disposed(by: disposeBag)
  }

  func showWalletsObservable() -> Observable<[[String]]> {
    return didTapWallet.withLatestFrom(Observable.just(self.dependency.authService.accounts())).map({ (items) -> [[String]] in
      return [items.map { (item) -> String in
        return self.pickerTitle(from: item)
      }]
    })
  }
  
  func itemFor(title: String) -> AccountItem? {
    return self.dependency.authService.accounts().filter { (item) -> Bool in
      return self.pickerTitle(from: item) == title
    }.first
  }

  func pickerTitle(from item: AccountItem) -> String {
    let address = TransactionTitleHelper.title(from: item.address)
    var accountTitle = item.address
    if let name = item.title {
      accountTitle = name + " (" + address + ")"
    }
    return accountTitle
  }

}
