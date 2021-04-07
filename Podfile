source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
 platform :ios, '12.0'

target 'Luca' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'CryptoSwift', '~> 1.0'
  pod 'MaterialComponents/TextFields'
  pod 'SwiftGen', '~> 6.0'
  pod 'Alamofire', '~> 5.2'
  pod 'JGProgressHUD'
  pod 'TTTAttributedLabel'
  pod 'SimpleCheckbox'
  pod 'IQKeyboardManagerSwift'
  pod 'Validator'
  pod 'PhoneNumberKit', '~> 3.3'
  pod 'Mocker', '~> 2.2.0'
  
  pod 'RxSwift'
  pod 'RxAppState'
  pod 'base64url'
  pod 'DeviceKit', '~> 3'
  pod 'LicensesViewController', '~> 0.9.0'
  pod 'RealmSwift'
  pod 'SwiftBase32'
  
  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        end
      end
  end
end
