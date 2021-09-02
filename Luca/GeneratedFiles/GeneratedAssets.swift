// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let luca1d1d1d = ColorAsset(name: "luca1d1d1d")
  internal static let luca747480 = ColorAsset(name: "luca747480")
  internal static let hello = ImageAsset(name: "Hello")
  internal static let accountActive = ImageAsset(name: "accountActive")
  internal static let addPersonBlack = ImageAsset(name: "addPersonBlack")
  internal static let addPersonWhite = ImageAsset(name: "addPersonWhite")
  internal static let arrowCircle = ImageAsset(name: "arrowCircle")
  internal static let calendar = ImageAsset(name: "calendar")
  internal static let cameraIcon = ImageAsset(name: "cameraIcon")
  internal static let checkinActive = ImageAsset(name: "checkinActive")
  internal static let checkmarkBlack = ImageAsset(name: "checkmarkBlack")
  internal static let closeButton = ImageAsset(name: "closeButton")
  internal static let editPencil = ImageAsset(name: "editPencil")
  internal static let emLogo = ImageAsset(name: "em_logo")
  internal static let eye = ImageAsset(name: "eye")
  internal static let healthAuthority = ImageAsset(name: "healthAuthority")
  internal static let historyActive = ImageAsset(name: "historyActive")
  internal static let hourglass = ImageAsset(name: "hourglass")
  internal static let infoIcon = ImageAsset(name: "infoIcon")
  internal static let lucaAlertTint = ColorAsset(name: "lucaAlertTint")
  internal static let lucaBG = ImageAsset(name: "lucaBG")
  internal static let lucaBeige = ColorAsset(name: "lucaBeige")
  internal static let lucaBlack = ColorAsset(name: "lucaBlack")
  internal static let lucaBlackLogo = ImageAsset(name: "lucaBlackLogo")
  internal static let lucaBlackLowAlpha = ColorAsset(name: "lucaBlackLowAlpha")
  internal static let lucaBlue = ColorAsset(name: "lucaBlue")
  internal static let lucaBlueGrey = ColorAsset(name: "lucaBlueGrey")
  internal static let lucaButtonBlack = ColorAsset(name: "lucaButtonBlack")
  internal static let lucaCameraButtonGrey = ColorAsset(name: "lucaCameraButtonGrey")
  internal static let lucaDarkBlue = ColorAsset(name: "lucaDarkBlue")
  internal static let lucaDarkBlueGrey = ColorAsset(name: "lucaDarkBlueGrey")
  internal static let lucaDarkGreenGrey = ColorAsset(name: "lucaDarkGreenGrey")
  internal static let lucaDarkGrey = ColorAsset(name: "lucaDarkGrey")
  internal static let lucaEMGreen = ColorAsset(name: "lucaEMGreen")
  internal static let lucaError = ColorAsset(name: "lucaError")
  internal static let lucaGradientWelcomeBegin = ColorAsset(name: "lucaGradientWelcomeBegin")
  internal static let lucaGradientWelcomeEnd = ColorAsset(name: "lucaGradientWelcomeEnd")
  internal static let lucaGreen = ColorAsset(name: "lucaGreen")
  internal static let lucaGreenGrey = ColorAsset(name: "lucaGreenGrey")
  internal static let lucaGrey = ColorAsset(name: "lucaGrey")
  internal static let lucaHealthGreen = ColorAsset(name: "lucaHealthGreen")
  internal static let lucaHealthRed = ColorAsset(name: "lucaHealthRed")
  internal static let lucaHealthYellow = ColorAsset(name: "lucaHealthYellow")
  internal static let lucaLaunchGrey = ColorAsset(name: "lucaLaunchGrey")
  internal static let lucaLightBlue = ColorAsset(name: "lucaLightBlue")
  internal static let lucaLightGreen = ColorAsset(name: "lucaLightGreen")
  internal static let lucaLightGrey = ColorAsset(name: "lucaLightGrey")
  internal static let lucaLogo = ImageAsset(name: "lucaLogo")
  internal static let lucaLogoBlack = ImageAsset(name: "lucaLogoBlack")
  internal static let lucaOrange = ColorAsset(name: "lucaOrange")
  internal static let lucaPurple = ColorAsset(name: "lucaPurple")
  internal static let lucaWhiteHalfAlpha = ColorAsset(name: "lucaWhiteHalfAlpha")
  internal static let lucaWhiteLowAlpha = ColorAsset(name: "lucaWhiteLowAlpha")
  internal static let lucaWhiteLowAlphaText = ColorAsset(name: "lucaWhiteLowAlphaText")
  internal static let lucaWhiteTextFieldBorder = ColorAsset(name: "lucaWhiteTextFieldBorder")
  internal static let lucaWhiteTextFieldFont = ColorAsset(name: "lucaWhiteTextFieldFont")
  internal static let myLuca = ImageAsset(name: "myLuca")
  internal static let noEntries = ImageAsset(name: "noEntries")
  internal static let plusSign = ImageAsset(name: "plusSign")
  internal static let scanner = ImageAsset(name: "scanner")
  internal static let sicherSein = ImageAsset(name: "sicherSein")
  internal static let sicherSeinBlack = ImageAsset(name: "sicherSeinBlack")
  internal static let viewMore = ImageAsset(name: "viewMore")
  internal static let viewMoreBlack = ImageAsset(name: "viewMoreBlack")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
