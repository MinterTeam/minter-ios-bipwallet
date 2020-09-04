//
//  SettingsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class SettingsViewModel: BaseViewModel, ViewModel {

  // MARK: -

  enum CellIdentifier: String {
    case changePIN
  }

  // MARK: -

  private var showPIN = PublishSubject<Void>()
  private var pinSubject = PublishSubject<String?>()
  private let didSelectModel = PublishSubject<BaseCellItem?>()
  private let viewWillAppear = PublishSubject<Void>()
  private let didTapLogout = PublishSubject<Void>()
  private let didTapOurChannel = PublishSubject<Void>()
  private let didTapSupport = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SettingsViewModel.Input!
  var output: SettingsViewModel.Output!
  var dependency: SettingsViewModel.Dependency!

  struct Input {
    var pin: AnyObserver<String?>
    var didSelectModel: AnyObserver<BaseCellItem?>
    var viewWillAppear: AnyObserver<Void>
    var didTapLogout: AnyObserver<Void>
    var didTapOurChannel: AnyObserver<Void>
    var didTapSupport: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var showPIN: Observable<Void>
    var changePIN: Observable<Void>
    var didTapLogout: Observable<Void>
    var didTapOurChannel: Observable<Void>
    var didTapSupport: Observable<Void>
  }

  struct Dependency {
    var pinService: PINService
    var authService: AuthService
    var appSettings: AppSettings
  }

  init(dependency: Dependency) {
    self.input = Input(pin: pinSubject.asObserver(),
                       didSelectModel: didSelectModel.asObserver(),
                       viewWillAppear: viewWillAppear.asObserver(),
                       didTapLogout: didTapLogout.asObserver(),
                       didTapOurChannel: didTapOurChannel.asObserver(),
                       didTapSupport: didTapSupport.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showPIN: showPIN.asObservable(),
                         changePIN: didSelectModel.filter { $0?.identifier == CellIdentifier.changePIN.rawValue }.map {_ in },
                         didTapLogout: didTapLogout.asObservable(),
                         didTapOurChannel: didTapOurChannel.asObservable(),
                         didTapSupport: didTapSupport.asObservable()
    )

    self.dependency = dependency

    super.init()

    self.createSections()

    bind()
  }

  // MARK: -

  private let sections = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)

  // MARK: -

  func bind() {
    viewWillAppear.subscribe(onNext: { [weak self] (_) in
      self?.createSections()
    }).disposed(by: disposeBag)
  }

  // MARK: - Sections

  func createSections() {
    var sctns = [BaseTableSectionItem]()

    let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                               identifier: "SeparatorTableViewCell")

    let switchItem = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                             identifier: "SwitchTableViewCell_Sound")
    switchItem.title = "Enable sounds".localized()
    switchItem.isOn = self.dependency.appSettings.isSoundEnabled
    switchItem.isOnSubject.subscribe(onNext: { [weak self] (val) in
      guard let `self` = self else { return }
      self.dependency.appSettings.isSoundEnabled = val
      if val {
        self.sound.onNext(.click)
      }
    }).disposed(by: disposeBag)

    let enablePin = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                            identifier: "SwitchTableViewCell_Pin")
    enablePin.title = "Unlock with PIN-code".localized()
    enablePin.isOnSubject.map{_ in }.subscribe(showPIN).disposed(by: disposeBag)
    enablePin.isOn = self.dependency.pinService.hasPIN()

    let enableBiometrics = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                                   identifier: "SwitchTableViewCell_Biometrics")

    enableBiometrics.title = "Unlock with fingerprint".localized()
    if #available(iOS 11.0, *) {
      if self.dependency.pinService.biometricType() == .faceID {
        enableBiometrics.title = "Unlock with FaceID".localized()
      }
    }
    enableBiometrics.isOn = self.dependency.pinService.isBiometricEnabled()
    enableBiometrics.isOnSubject.subscribe(onNext: { [weak self] val in
      guard let `self` = self else { return }
      self.dependency.pinService.setBiometric(enabled: val)
    }).disposed(by: disposeBag)

    let changePin = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
                                                identifier: CellIdentifier.changePIN.rawValue)
    changePin.title = "Change PIN-code".localized()
    changePin.value = nil
    changePin.placeholder = ""

    var section1 = BaseTableSectionItem(identifier: "SECURITY", header: "SECURITY".localized())
    section1.items = [enablePin]

    if dependency.pinService.canUseBiometric() && dependency.pinService.hasPIN() {
      section1.items.append(contentsOf: [enableBiometrics])
    }
    if dependency.pinService.hasPIN() {
      section1.items.append(contentsOf: [changePin])
    }

    sctns.append(section1)

    var section2 = BaseTableSectionItem(identifier: String.random(), header: "NOTIFICATIONS".localized())
    section2.items = [switchItem]
    sctns.append(section2)

    var section3 = BaseTableSectionItem(identifier: "STORIES", header: "STORIES".localized())

    let storiesItem = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                             identifier: "SwitchTableViewCell_Stories")
    storiesItem.title = "Show Stories".localized()
    storiesItem.isOn = self.dependency.appSettings.showStories
    storiesItem.isOnSubject.subscribe(onNext: { [weak self] (val) in
      guard let `self` = self else { return }
      self.dependency.appSettings.showStories = val
      self.sound.onNext(.click)
    }).disposed(by: disposeBag)
    section3.items = [storiesItem]

    sctns.append(section3)

    sections.onNext(sctns)
  }

}
