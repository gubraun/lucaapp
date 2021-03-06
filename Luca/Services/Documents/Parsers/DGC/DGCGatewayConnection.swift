//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  GatewayConnection.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/24/21.
//  

import Foundation
import Alamofire
import SwiftDGC
import SwiftyJSON
import UIKit

struct DGCGatewayConnection: ContextConnection {
  public static func certUpdate(resume resumeToken: String? = nil, completion: ((String?, String?) -> Void)?) {
    var headers = [String: String]()
    if let token = resumeToken {
      headers["x-resume-token"] = token
    }
    request(
      ["endpoints", "update"],
      method: .get,
      encoding: URLEncoding(),
      headers: .init(headers)
    ).response {
      if
        let status = $0.response?.statusCode,
        status == 204 {
        completion?(nil, nil)
        return
      }
      guard
        case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let headers = $0.response?.headers,
        let responseKid = headers["x-kid"],
        let newResumeToken = headers["x-resume-token"]
      else {
        return
      }
      let kid = KID.from(responseStr)
      let kidStr = KID.string(from: kid)
      if kidStr != responseKid {
        return
      }
      completion?(responseStr, newResumeToken)
    }
  }
  public static func certStatus(resume resumeToken: String? = nil, completion: (([String]) -> Void)?) {
    request(["endpoints", "status"]).response {
      guard
        case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let json = JSON(parseJSON: responseStr).array
      else {
        return
      }
      let kids = json.compactMap { $0.string }
      completion?(kids)
    }
  }

  static var timer: Timer?

  public static func initialize() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
      trigger()
    }
    timer?.tolerance = 5.0
    trigger()
  }

  static func trigger() {
    guard DGCLocalData.sharedInstance.lastFetch.timeIntervalSinceNow < -24 * 60 * 60 else {
      return
    }
    fetchContext {
      update()
    }
  }

  static func update(completion: (() -> Void)? = nil) {
    certUpdate(resume: DGCLocalData.sharedInstance.resumeToken) { encodedCert, token in
      guard let encodedCert = encodedCert else {
        status(completion: completion)
        return
      }
      DGCLocalData.sharedInstance.add(encodedPublicKey: encodedCert)
      DGCLocalData.sharedInstance.resumeToken = token
      update(completion: completion)
    }
  }

  static func status(completion: (() -> Void)? = nil) {
    certStatus { validKids in
      let invalid = DGCLocalData.sharedInstance.encodedPublicKeys.keys.filter {
        !validKids.contains($0)
      }
      for key in invalid {
        DGCLocalData.sharedInstance.encodedPublicKeys.removeValue(forKey: key)
      }
      DGCLocalData.sharedInstance.lastFetch = Date()
      DGCLocalData.sharedInstance.save()
      completion?()
    }
  }

  public static func fetchContext(completion: (() -> Void)? = nil) {
    request(
      ["context"]
    ).response {
      guard
        let data = $0.data,
        let string = String(data: data, encoding: .utf8)
      else {
        completion?()
        return
      }
      let json = JSON(parseJSONC: string)
      DGCLocalData.sharedInstance.config.merge(other: json)
      DGCLocalData.sharedInstance.save()
      if DGCLocalData.sharedInstance.versionedConfig["outdated"].bool == true {
        (
          UIApplication.shared.windows[0].rootViewController as? UINavigationController
        )?.popToRootViewController(animated: false)
        return
      }
      completion?()
    }
  }
  static var config: JSON {
    DGCLocalData.sharedInstance.versionedConfig
  }
}
