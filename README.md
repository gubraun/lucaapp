# Luca iOS App

[luca](https://luca-app.de) ensures a data protection-compliant, decentralized encryption of your data, undertakes the obligation to record contact data for events and gastronomy, relieves the health authorities through digital, lean, and integrated processes to enable efficient and complete tracing.

## Development Requirements and Restrictions
- iOS 12.0+
- Xcode 10.0+
- Cocoapods
- support only for iPhone

## Development Setup
1. Install Xcode 10.0 or higher
2. Install Cocoapods via
     `sudo gem install cocoapods`
     If this is not working for you, you can find additional installation instructions [here](https://guides.cocoapods.org/using/getting-started.html#getting-started)
 3. Run `pod install` within the project directory to install all dependencies
 
 We use two different schemes called  `debug` and  `release`. They might behave differently as `debug` builds for example use different API endpoints.   

## Usage instructions
In order to use the app, you need a valid phone number. You'll need it to pass the verification during the registration process.

## Changelog
An overview of all releases can be found [here](https://gitlab.com/lucaapp/ios/-/blob/master/CHANGELOG.md).

## Issues & Support

Please [create an issue](https://gitlab.com/lucaapp/ios/-/issues) for suggestions or problems related to this app. For general questions, please check out our [FAQ](https://www.luca-app.de/faq/) or contact our support team at [hello@luca-app.de](mailto:hello@luca-app.de).

## License

The Luca iOS App is Free Software (Open Source) and is distributed
with a number of components with compatible licenses.

```
SPDX-License-Identifier: Apache-2.0

SPDX-FileCopyrightText: 2021 culture4life GmbH <https://luca-app.de>
```

For details see
 * [license file](./LICENSE)
 * [Acknowledgements](./Luca/Credits.plist)
