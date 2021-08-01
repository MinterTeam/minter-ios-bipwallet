source 'https://github.com/Cocoapods/Specs'
use_frameworks!

platform :ios, '11.0'

def shared_pods
  #Minter
	pod 'MinterCore', :path => '../../minter-ios-core'#'~> 1.2.4'
	pod 'MinterMy'
	pod 'MinterExplorer', :path => '../../minter-ios-explorer'
  #Networking
	pod 'Alamofire'
	pod 'AlamofireImage'
  pod 'ObjectMapper', '~> 3.3'
  #Rx
	pod 'RxSwift'
	pod 'RxBiBinding'
	pod 'RxGesture'
	pod 'RxDataSources'
	pod 'RxAppState'
  pod 'RxSwiftExt'
  pod 'RxRouting', :git => 'https://github.com/e-sites/RxRouting.git'
  pod 'RxReachability'
  #DB/Storage
  pod 'RealmSwift', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: true
  pod 'GoldenKeystore', :git => 'https://github.com/sidorov-panda/GoldenKeystore'
  #UI
  pod 'SnapKit'
	pod 'TPKeyboardAvoiding'
  pod 'AFDateHelper', '~> 4.2.2'
	pod 'XLPagerTabStrip', '~> 8.0'
  pod 'DeckTransition'
  pod 'CardPresentationController', :git => 'https://github.com/radianttap/CardPresentationController.git'
  pod 'NotificationBannerSwift'
  #Analytics
	pod 'YandexMobileMetrica/Dynamic', '3.2.0'
  #Sys
  pod 'SwiftCentrifuge'
  pod 'ReachabilitySwift', '~> 4.3'
	pod 'SwiftLint'
  pod 'Swinject'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'CryptoSwift', '~> 1.0'
  pod 'KeychainSwift'
  pod 'SwiftValidator', :git => 'https://github.com/jpotts18/SwiftValidator.git', :tag => '4.2.0'
end

target 'BIPWallet' do
	shared_pods
end

target 'BIPWalletTestnet' do
  shared_pods
end
