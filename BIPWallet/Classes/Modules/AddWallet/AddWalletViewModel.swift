//
//  AddWalletViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import RxCocoa
import GoldenKeystore

enum AddWalletViewModelError: Error {
  case invalidMnemonics
  case invalidTitle
}

class AddWalletViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let viewDidDisappear = PublishSubject<Bool>()
  private let isSwichOn = PublishSubject<Bool>()
  private let mnemonics = BehaviorRelay<String?>(value: String.generateMnemonicString())
  private let didTapActivate = PublishSubject<Void>()
  private let accountAdded = PublishSubject<AccountItem>()
  private let didTapMnemonic = PublishSubject<Void>()
  private let title = BehaviorRelay<String?>(value: nil)
  private let signInMnemonics = BehaviorRelay<String?>(value: nil)
  private let signInTitle = BehaviorRelay<String?>(value: nil)
  private var shakeError = PublishSubject<Void>()
  private var errorMessage = PublishSubject<String>()
  private var hardImpact = PublishSubject<Void>()
  private var titleDidEndEditing = PublishSubject<Void>()
  private var isLoading = PublishSubject<Bool>()
  private var titleError = PublishSubject<String?>()
  private var mnemonicsError = PublishSubject<String?>()
  private let didTapGenerateWallet = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: AddWalletViewModel.Input!
  var output: AddWalletViewModel.Output!
  var dependency: AddWalletViewModel.Dependency!

  struct Input {
    var viewDidDisappear: AnyObserver<Bool>
    //GenerateWallet
    var isSwichOn: AnyObserver<Bool>
    var didTapActivate: AnyObserver<Void>
    var didTapMnemonic: AnyObserver<Void>
    var title: BehaviorRelay<String?>
    var mnemonics: BehaviorRelay<String?>
    //Add wallet
    var signInMnemonics: BehaviorRelay<String?>
    var signInTitle: BehaviorRelay<String?>
    var titleDidEndEditing: PublishSubject<Void>
    var didTapGenerateWallet: PublishSubject<Void>
  }

  struct Output {
    var viewDidDisappear: Observable<Bool>
    var mnemonics: Observable<String?>
    var isButtonEnabled: Observable<Bool>
    var accountAdded: Observable<AccountItem>
    var shakeError: Observable<Void>
    var errorMessage: Observable<String>
    var hardImpact: Observable<Void>
    var isLoading: Observable<Bool>
    var buttonTitle: Observable<String?>
    var titleError: Observable<String?>
    var mnemonicsError: Observable<String?>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {
    super.init()

    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver(),
                       isSwichOn: isSwichOn.asObserver(),
                       didTapActivate: didTapActivate.asObserver(),
                       didTapMnemonic: didTapMnemonic.asObserver(),
                       title: title,
                       mnemonics: mnemonics,
                       signInMnemonics: signInMnemonics,
                       signInTitle: signInTitle,
                       titleDidEndEditing: titleDidEndEditing.asObserver(),
                       didTapGenerateWallet: didTapGenerateWallet.asObserver()
    )

    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable(),
                         mnemonics: mnemonics.asObservable(),
                         isButtonEnabled: Observable.combineLatest(isSwichOn, isLoading.startWith(false), mnemonics.asObservable(), title.asObservable())
                          .map { $0.0 && !$0.1 && mnemonicIsValid($0.2 ?? "") && (($0.3?.isEmpty ?? true) ? true : ($0.3?.isValidWalletTitle() ?? true)) },
                         accountAdded: accountAdded.asObservable(),
                         shakeError: shakeError.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         hardImpact: hardImpact.asObservable(),
                         isLoading: isLoading.asObservable(),
                         buttonTitle: isLoading.startWith(false).map { $0 ? "" : "Activate Wallet".localized() },
                         titleError: titleError.asObservable(),
                         mnemonicsError: mnemonicsError.asObservable()
    )

    self.dependency = dependency

    bind()
  }

  // MARK: -

  func bind() {

    didTapGenerateWallet.map{ _ in nil }.subscribe(titleError).disposed(by: disposeBag)

    signInMnemonics.distinctUntilChanged().map { _ in
      return nil
    }
    .subscribe(mnemonicsError)
    .disposed(by: disposeBag)

    signInTitle.distinctUntilChanged().map { _ in
      return nil
    }.subscribe(titleError).disposed(by: disposeBag)

    didTapMnemonic.asObservable().withLatestFrom(mnemonics)
      .subscribe(onNext: { (mnemonic) in
        guard let mnemonic = mnemonic else {
          //show error
          return
        }
        UIPasteboard.general.string = mnemonic
      }).disposed(by: disposeBag)

    let generateWallet = didTapActivate.asObservable()
      .withLatestFrom(Observable.combineLatest(mnemonics.asObservable(), title.asObservable()))

    let signInWallet = titleDidEndEditing.withLatestFrom(Observable.combineLatest(signInMnemonics, signInTitle))

    Observable.merge(generateWallet, signInWallet)
      .flatMap({ (val) -> Observable<Event<AccountItem>> in
        return self.observer(observable: val).materialize()
      })
      .subscribe(onNext: { [weak self] (event) in
        switch event {
        case .error(let error):
          self?.handleError(error)
        case .next(let account):
          self?.accountAdded.onNext(account)
        default:
          return
        }
      }).disposed(by: disposeBag)
  }

  func observer(observable: (String?, String?)) -> Observable<AccountItem> {
    return Observable<(String?, String?)>.just(observable)
      .map({ (val) -> (String?, String?) in
        let mnemonics = val.0
        let title = val.1
        let newMnemonics = mnemonics?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let newTitle = title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return (newMnemonics, newTitle)
      }).flatMap({ (val) -> Observable<(String, String?)> in
        return self.validateForm(mnemonics: val.0, title: val.1)
      }).flatMap({ [weak self] (val) -> Observable<AccountItem> in
        guard let `self` = self else { return Observable.empty() }
        return self.dependency.authService.addAccount(with: val.0, title: val.1)
      .do(onNext: { [weak self] (event) in
          self?.isLoading.onNext(false)
      }, onError: { [weak self] error in
          self?.handleError(error)
          self?.isLoading.onNext(false)
      }, onSubscribe: { [weak self] in
          self?.isLoading.onNext(true)
      })
    })
  }

  func validateForm(mnemonics: String?, title: String?) -> Observable<(String, String?)> {
    return Observable<(String, String?)>.create { (observer) -> Disposable in
      if !mnemonicIsValid(mnemonics ?? "") {
        observer.onError(AddWalletViewModelError.invalidMnemonics)

      //If there is no title -> pass. if title exists - check if it's valid
      } else if !(title ?? "").isValidWalletTitle() && !(title ?? "").isEmpty {
        observer.onError(AddWalletViewModelError.invalidTitle)
      } else {
        observer.onNext((mnemonics ?? "", title))
      }
      return Disposables.create()
    }
  }

  func handleError(_ error: Error) {
    self.shakeError.onNext(())
    if let error = error as? AuthServiceError {
      switch error {
      case .dublicateAddress:
        self.mnemonicsError.onNext("You've already added this wallet".localized())
      case .invalidMnemonic:
        self.mnemonicsError.onNext("Invalid mnemonic phrase".localized())
      case .titleTaken:
        self.titleError.onNext("Wallet with such title already exists".localized())
      default:
        self.errorMessage.onNext("Unable to add wallet".localized())
      }
    } else if let error = error as? AddWalletViewModelError {
      switch error {
      case .invalidMnemonics:
        self.errorMessage.onNext("Invalid mnemonics".localized())
      case .invalidTitle:
        self.titleError.onNext("Invalid title".localized())
      }
    } else {
      self.errorMessage.onNext("Unable to add wallet".localized())
      return
    }
  }

}
