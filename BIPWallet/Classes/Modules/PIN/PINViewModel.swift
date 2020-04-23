//
//  PINViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import LocalAuthentication

class PINViewModel: BaseViewModel, ViewModel {

  var title: String?
  var desc: String?
  var errorMessage: String?
  var isBiometricEnabled: Bool = false

  // MARK: -

  private var titleSubject: PublishSubject<String> = PublishSubject()
  private var descSubject: PublishSubject<String> = PublishSubject()
  private var viewDidLoadSubject: PublishSubject<Void> = PublishSubject()
  private var viewDidAppearSubject: PublishSubject<Bool> = PublishSubject()
  private let unlockedWithBiometrics = PublishSubject<Void>()
  let pin = BehaviorSubject<String>(value: "")
  var shakeError = PublishSubject<Void>()

  // MARK: -

  struct Input {
    var viewDidLoad: AnyObserver<Void>
    var viewDidAppear: AnyObserver<Bool>
    var pin: AnyObserver<String>
  }

  struct Output {
    var title: Observable<String>
    var desc: Observable<String>
    var pin: Observable<String>
    var shakeError: Observable<Void>
    var unlockedWithBiometrics: Observable<Void>
  }

  struct Dependency {
    var pinService: PINService
  }

  var input: PINViewModel.Input!
  var output: PINViewModel.Output!
  var dependency: PINViewModel.Dependency!

  // MARK: -

  init(dependency: Dependency) {
    super.init()

    input = Input(viewDidLoad: viewDidLoadSubject.asObserver(),
                  viewDidAppear: viewDidAppearSubject.asObserver(),
                  pin: pin.asObserver()
    )

    output = Output(title: titleSubject.asObservable(),
                    desc: descSubject.asObservable(),
                    pin: pin.asObservable(),
                    shakeError: shakeError.asObservable(),
                    unlockedWithBiometrics: unlockedWithBiometrics.asObservable()
    )

    self.dependency = dependency

    viewDidLoadSubject.subscribe(onNext: { [weak self] (_) in
      self?.titleSubject.onNext(self?.title ?? "")
      self?.descSubject.onNext(self?.desc ?? "")
    }).disposed(by: disposeBag)

    viewDidAppearSubject.subscribe(onNext: { [weak self] (_) in
      if self?.isBiometricEnabled ?? false {
        self?.dependency.pinService.checkBiometricsIfPossible(with: { (res) in
          if res {
            DispatchQueue.main.async {
              self?.dependency.pinService.unlockWithBiometrics()
              self?.unlockedWithBiometrics.onNext(())
            }
          }
        })
      }
    }).disposed(by: disposeBag)

  }

}
