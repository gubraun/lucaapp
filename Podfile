source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
 platform :ios, '12.0'

def shared_podfiles
  pod 'RealmSwift', '~> 5.5.1'
  pod 'RxSwift', '~> 6.1.0'
  pod 'RxBlocking', '~> 6.1.0'
  pod 'CryptoSwift', '~> 1.4.0'
end

target 'LucaTests' do
  use_frameworks!
  
  shared_podfiles
end

target 'Luca' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  shared_podfiles
  
  pod 'Alamofire', '~> 5.4.3'
  pod 'base64url', '~> 1.1.0'
  pod 'DeviceKit', '~> 4.4.0'
  pod 'IQKeyboardManagerSwift', '~> 6.5.6'
  pod 'JGProgressHUD', '~> 2.2'
  pod 'LicensesViewController', '~> 0.9.0'
  pod 'MaterialComponents/TextFields', '~> 124.1.1'
  pod 'Mocker', '~> 2.2.0'
  pod 'PhoneNumberKit', '~> 3.3.3'
  pod 'RxAppState', '~> 1.7.0'
  pod 'SimpleCheckbox', '~> 2.1.0'
  pod 'Sourcery', '~> 1.4.1'
  pod 'SwiftBase32', '~> 0.9.0'
  pod 'SwiftCBOR', '~> 0.4.3'
  pod 'SwiftGen', '~> 6.4.0'
  pod 'SwiftJWT', '~> 3.6.200'
  pod 'SwiftLint', '~> 0.43.1'
  pod 'TTTAttributedLabel', '~> 2.0.0'
  pod 'Validator', '~> 3.2.1'
  
  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        end
      end
  end
end
