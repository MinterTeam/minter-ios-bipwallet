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

  // MARK: - ViewModel

  var input: SettingsViewModel.Input!
  var output: SettingsViewModel.Output!
  var dependency: SettingsViewModel.Dependency!

  struct Input {

  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
  }

  struct Dependency {

  }

  init(dependency: Dependency) {
    self.input = Input()

    self.output = Output(sections: sections.asObservable()
    )

    self.dependency = dependency

    super.init()

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      self.createSections()
    }
  }

  // MARK: -

  private let sections = PublishSubject<[BaseTableSectionItem]>()

  // MARK: - Sections

  func createSections() {

    var sctns = [BaseTableSectionItem]()

    let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                               identifier: "SeparatorTableViewCell")
//
//    let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
//                                         identifier: "ButtonTableViewCell_Logout")
//    button.buttonPattern = "blank"
//    button.title = "LOG OUT".localized()

//    let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
//                                       identifier: "BlankTableViewCell")
//    blank.color = .clear

    let switchItem = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                             identifier: "SwitchTableViewCell_Sound")
    switchItem.title = "Enable sounds".localized()
//    switchItem.isOn.value = AppSettingsManager.shared.isSoundsEnabled

    let enablePin = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                            identifier: "SwitchTableViewCell_Pin")
    enablePin.title = "Unlock with PIN-code".localized()
//    enablePin.isOn.value = PINManager.shared.isPINset
//    enablePin.isOnObservable = pincodeSubject.asObservable()

    let enableBiometrics = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
                                                   identifier: "SwitchTableViewCell_Biometrics")

    enableBiometrics.title = "Unlock with fingerprint".localized()
    if #available(iOS 11.0, *) {
//      if PINManager.shared.biometricType() == .faceID {
//        enableBiometrics.title = "Unlock with FaceID".localized()
//      }
    }
//    enableBiometrics.isOn.value = AppSettingsManager.shared.isBiometricsEnabled && PINManager.shared.isPINset
//    enableBiometrics.isOnObservable = fingerprintSubject.asObservable()

    let changePin = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
                                                identifier: "DisclosureTableViewCell_ChangePIN")
    changePin.title = "Change PIN-code".localized()
    changePin.value = nil
    changePin.placeholder = ""

    var section1 = BaseTableSectionItem(identifier: "SECURITY", header: "SECURITY".localized())
    section1.items = [enablePin]

//    if PINManager.shared.canUseBiometric() {
//      section1.items.append(contentsOf: [enableBiometrics, separator])
//    }
//    if PINManager.shared.isPINset {
//      section1.items.append(contentsOf: [changePin, separator])
//    }

    sctns.append(section1)

    var section2 = BaseTableSectionItem(identifier: String.random(), header: "NOTIFICATIONS".localized())
    section2.items = [switchItem]
    sctns.append(section2)

    sections.onNext(sctns)
  }

}
