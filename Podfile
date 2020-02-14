source 'https://github.com/Cocoapods/Specs'
use_frameworks!

platform :ios, '11.0'

def shared_pods
  #Minter
	pod 'MinterCore', :git => 'https://github.com/MinterTeam/minter-ios-core.git', :branch => 'texas'
	pod 'MinterMy'#, :path => '../../minter-ios-my'
	pod 'MinterExplorer'#, :path => '../../minter-ios-explorer'
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
  #DB/Storage
#  pod 'RealmSwift', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: true
  pod 'GoldenKeystore', :git => 'https://github.com/sidorov-panda/GoldenKeystore'
  #UI
  pod 'SnapKit'
	pod 'TPKeyboardAvoiding'
	pod 'NotificationBannerSwift', '1.8.0'
  pod 'AFDateHelper', '~> 4.2.2'
	pod 'XLPagerTabStrip', '~> 8.0'
  #Analytics
	pod 'YandexMobileMetrica/Dynamic', '3.2.0'
  #Sys
  pod 'SwiftCentrifuge'
  pod 'ReachabilitySwift', '~> 4.3'
	pod 'SwiftLint'
  pod 'Swinject'
  pod 'Fabric', '~> 1.7'
  pod 'Crashlytics', '~> 3.10'
  pod 'CryptoSwift', '~> 1.0'
  pod 'KeychainSwift'
end

target 'BIPWallet' do
	shared_pods
end
