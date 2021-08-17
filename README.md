# Luca iOS App

[luca](https://luca-app.de) ensures a data protection-compliant, decentralized encryption of your data, undertakes the obligation to record contact data for events and gastronomy, relieves the health authorities through digital, lean, and integrated processes to enable efficient and complete tracing.

## Development Requirements and Restrictions
- iOS 12.0+
- Xcode 12.5+
- Cocoapods
- support only for iPhone

## Development Setup
1. Install Xcode 12.5 or higher
2. Install Cocoapods via
    `sudo gem install cocoapods`
    If this is not working for you, you can find additional installation instructions [here](https://guides.cocoapods.org/using/getting-started.html#getting-started)
3. Run `pod install` within the project directory to install all dependencies
4. Staging backend needs authentication so there are two environment variables needed:
    1. `BACKEND_LOGIN` and `BACKEND_PASSWORD`
    2. Those strings are URL Encoded
    3. Alternatively, if you don't want to set those variables in the environment, you can create a file `env-vars_$CONFIGURATION.sh` in the root directory. For debug it would be `env-vars_Debug.sh` and for QA `env-vars_QA.sh`. Files matching `env-vars_*.sh` pattern are added to `.gitignore`, so they won't be added to the repository. The content of the file should look like this:
```
    export BACKEND_LOGIN="[URL_ENCODED_LOGIN]"
    export BACKEND_PASSWORD="[URL_ENCODED_PASSWORD]"
```
  
We use following schemes:
- `Luca Development`: development
- `Luca QA`: manual testing
- `Luca Pentest`: pentesting
- `Luca Release`: release testing
- `Luca Hotfix`: hotfix testing
- `Luca Preprod`: final smoke testing
- `Luca Production`: production

They may behave differently as they point to different API endpoints.
 
### SwiftLint
We use [SwiftLint](https://github.com/realm/SwiftLint) to ensure Swift style and conventions. 
You can run `swiftlint autocorrect` to let SwiftLint format your code according to the rules set up for our project. There is also a lot of helpful information on how the tool works in there [documentation](https://github.com/realm/SwiftLint).

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
