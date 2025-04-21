//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 31/08/2023.
//

import UIKit
import FirebaseAnalytics
import FirebaseDatabase

class LogEventManager {
  static let shared = LogEventManager()
  
  private var isWarning = false
  
  func log(event: Event) {
#if DEBUG
    LogManager.show(log: .event, "[\(isValid(event.name))]", event.name, event.parameters ?? String())
    if !isValid(event.name) {
      showWarning()
    }
    pushTestEvent(event: event.name)
#endif
#if !DEBUG
    Analytics.logEvent(event.name, parameters: event.parameters)
#endif
  }
  
  func checkFormat(adConfig: AdMobConfig) {
    let maxCharacter = 23
    
    let body: ((AdConfigProtocol) -> Void) = { [weak self] ad in
      guard let self else {
        return
      }
      if !isValid(ad.placement, limit: maxCharacter) || !isValid(ad.name, limit: maxCharacter) {
        showWarning()
        return
      }
    }
    
    adConfig.splashs?.forEach(body)
    adConfig.appOpens?.forEach(body)
    adConfig.interstitials?.forEach(body)
    adConfig.rewardeds?.forEach(body)
    adConfig.rewardedInterstitials?.forEach(body)
    adConfig.banners?.forEach(body)
    adConfig.natives?.forEach(body)
  }
}

extension LogEventManager {
  private func isValid(_ input: String, limit: Int = 40) -> Bool {
      // Danh sách sự kiện mặc định của Firebase (không phân biệt hoa thường)
      let reservedEventNames: Set<String> = [
          "ad_click", "ad_exposure", "ad_impression", "ad_query", "ad_reward",
          "app_clear_data", "app_exception", "app_remove", "app_store_refund",
          "app_store_subscription_cancel", "app_store_subscription_convert",
          "app_store_subscription_renew", "app_update", "app_upgrade", "begin_checkout",
          "campaign_details", "checkout_progress", "earn_virtual_currency", "ecommerce_purchase",
          "generate_lead", "join_group", "level_end", "level_start", "level_up",
          "login", "post_score", "purchase_refund", "search", "select_content",
          "set_checkout_option", "share", "sign_up", "spend_virtual_currency",
          "tutorial_begin", "tutorial_complete", "unlock_achievement", "view_item",
          "view_item_list", "view_search_results", "session_start", "app_open"
      ]

      // 1️⃣ Kiểm tra độ dài
      guard input.count <= limit else { return false }
      
      // 2️⃣ Kiểm tra khoảng trắng
      guard !input.contains(" ") else { return false }

      // 3️⃣ Kiểm tra ký tự hợp lệ: Chỉ chứa chữ cái, số và "_", không bắt đầu bằng số
      let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
      do {
          let regex = try NSRegularExpression(pattern: pattern)
          let range = NSRange(location: 0, length: input.utf16.count)
          guard regex.firstMatch(in: input, options: [], range: range) != nil else { return false }
      } catch {
          return false
      }

      // 4️⃣ Kiểm tra trùng với event mặc định của Firebase
      return !reservedEventNames.contains(input.lowercased())
  }
  
  private func showWarning() {
    guard !isWarning else {
      return
    }
    self.isWarning = true
    
    guard let topVC = UIApplication.topStackViewController() else {
      return
    }
    let alert = UIAlertController(title: "Error", message: "Missing event", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
      guard let self else {
        return
      }
      self.isWarning = false
    }))
    topVC.present(alert, animated: true)
  }
  
  private func pushTestEvent(event: String) {
    guard let deviceId = UIDevice.current.identifierForVendor else { return }
    
    let referencePath = "debug_events/\(String(describing: deviceId))"
    
    // Get a reference to the Firebase Database
    let databaseRef = Database.database().reference(withPath: referencePath)
    
    // Push a new value to the database
    databaseRef.childByAutoId().setValue(event)
  }
}

enum Event {
  case register
  
  case remoteConfigLoadFail
  case remoteConfigTimeout
  case remoteConfigStartLoad
  case remoteConfigSuccess
  case remoteConfigErrorWithTimeout
  
  case cmpCheckConsent
  case cmpNotRequestConsent
  case cmpRequestConsent
  case cmpConsentInformationError
  case cmpConsentFormError
  case cmpAgreeConsent
  case cmpRejectConsent
  case cmpAutoAgreeConsent
  case cmpAutoAgreeConsentGDPR
  
  case connectedAppsFlyer
  case noConnectAppsFlyer
  case agreeTracking
  case noTracking
  
  case adLoadRequest(String)
  case adLoadSuccess(String, Double)
  case adLoadFail(String, Error?)
  case adLoadTryFail(String, Error?)
  case adLoadTimeout(String)
  case adShowCheck(String, UIViewController? = nil)
  case adShowRequest(String, UIViewController? = nil)
  case adShowReady(String, UIViewController? = nil)
  case adShowNoReady(String, UIViewController? = nil)
  case adShowSuccess(String, UIViewController? = nil)
  case adShowFail(String, Error?, UIViewController? = nil)
  case adShowHide(String, UIViewController? = nil)
  case adShowClick(String, UIViewController? = nil)
  case adEarnReward(String, UIViewController? = nil)
  case adPayRevenue(String, UIViewController? = nil)
  case adNoRevenue(String, UIViewController? = nil)
  
  var name: String {
    switch self {
    case .remoteConfigLoadFail:
      return "RemoteConfig_First_Load_Fail"
    case .remoteConfigTimeout:
      return "RemoteConfig_First_Load_Timeout"
    case .remoteConfigErrorWithTimeout:
      return "RemoteConfig_First_Load_Error_With_Timeout"
    case .register:
      return "Register"
    case .remoteConfigStartLoad:
      return "RemoteConfig_Start_Load"
    case .remoteConfigSuccess:
      return "remoteConfig_Success"
      
    case .cmpCheckConsent:
      return "CMP_Check_Consent"
    case .cmpNotRequestConsent:
      return "CMP_Not_Request_Consent"
    case .cmpRequestConsent:
      return "CMP_Request_Consent"
    case .cmpConsentInformationError:
      return "CMP_Consent_Information_Error"
    case .cmpConsentFormError:
      return "CMP_Consent_Form_Error"
    case .cmpAgreeConsent:
      return "CMP_Agree_Consent"
    case .cmpRejectConsent:
      return "CMP_Reject_Consent"
    case .cmpAutoAgreeConsent:
      return "CMP_Auto_Agree_Consent"
    case .cmpAutoAgreeConsentGDPR:
      return "CMP_Auto_Agree_Consent_GDPR"
      
    case .connectedAppsFlyer:
      return "Connected_AppsFlyer"
    case .noConnectAppsFlyer:
      return "NoConnect_AppsFlyer"
    case .agreeTracking:
      return "Agree_Tracking"
    case .noTracking:
      return "No_Tracking"
      
    case .adLoadRequest(let name):
      return "AM_\(name)_Load_Request"
    case .adLoadSuccess(let name, _):
      return "AM_\(name)_Load_Success"
    case .adLoadFail(let name, _):
      return "AM_\(name)_Load_Fail"
    case .adLoadTryFail(let name, _):
      return "AM_\(name)_Load_TryFail"
    case .adLoadTimeout(let name):
      return "AM_\(name)_Load_Timeout"
    case .adShowCheck(let placement, _):
      return "AM_\(placement)_Show_Check"
    case .adShowRequest(let placement, _):
      return "AM_\(placement)_Show_Request"
    case .adShowReady(let placement, _):
      return "AM_\(placement)_Show_Ready"
    case .adShowNoReady(let placement, _):
      return "AM_\(placement)_Show_NoReady"
    case .adShowSuccess(let placement, _):
      return "AM_\(placement)_Show_Success"
    case .adShowFail(let placement, _, _):
      return "AM_\(placement)_Show_Fail"
    case .adShowHide(let placement, _):
      return "AM_\(placement)_Show_Hide"
    case .adShowClick(let placement, _):
      return "AM_\(placement)_Show_Click"
    case .adEarnReward(let placement, _):
      return "AM_\(placement)_Earn_Reward"
    case .adPayRevenue(let placement, _):
      return "AM_\(placement)_Pay_Revenue"
    case .adNoRevenue(let placement, _):
      return "AM_\(placement)_No_Revenue"
    }
  }
  
  var parameters: [String: Any]? {
    switch self {
    case .adLoadSuccess(_, let time):
      return ["time": time]
    case .adLoadFail(_, let error), .adLoadTryFail(_, let error):
      return ["error_code": (error as? NSError)?.code ?? "-1"]
    case .adShowCheck(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowRequest(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowReady(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowNoReady(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowSuccess(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowHide(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowClick(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adEarnReward(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adPayRevenue(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adNoRevenue(_, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return ["screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen()]
    case .adShowFail(_, let error, let viewController):
      guard let topVC = UIApplication.topStackViewController() else {
        return nil
      }
      return [
        "screen": (viewController ?? AdMobManager.shared.rootViewController ?? topVC).getScreen(),
        "error_code": (error as? NSError)?.code ?? "-1"
      ]
    default:
      return nil
    }
  }
}
