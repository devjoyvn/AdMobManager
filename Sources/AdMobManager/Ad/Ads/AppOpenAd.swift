//
//  AppOpenAd.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
// import AppsFlyerAdRevenue
// import AppsFlyerLib

class AppOpenAd: NSObject, AdProtocol {
  private var appOpenAd: GADAppOpenAd?
  private var adUnitID: String?
  private var placement: String?
  private var name: String?
  private var isShowing = false
  private var isLoading = false
  private var retryAttempt = 0
  private var didLoadFail: Handler?
  private var didLoadSuccess: Handler?
  private var didShowFail: Handler?
  private var willPresent: Handler?
  private var didEarnReward: Handler?
  private var didHide: Handler?
  private var loadTime: Date?
  private var timeInterval: TimeInterval?
  
  func config(didFail: Handler?, didSuccess: Handler?) {
    self.didLoadFail = didFail
    self.didLoadSuccess = didSuccess
  }
  
  func config(id: String, name: String) {
    self.adUnitID = id
    self.name = name
    load()
  }
  
  func config(timeInterval: Double) {
    self.timeInterval = timeInterval
  }
  
  func isPresent() -> Bool {
    return isShowing
  }
  
  func isExist() -> Bool {
    return appOpenAd != nil
  }
  
  func show(placement: String,
            rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard !isShowing else {
      LogManager.show(log: .ad, "[AppOpenAd] Display failure - ads are being displayed! (\(placement)))")
      didFail?()
      return
    }
    LogEventManager.shared.log(event: .adShowRequest(placement))
    guard isReady() else {
      LogManager.show(log: .ad, "[AppOpenAd] Display failure - not ready to show! (\(placement)")
      LogEventManager.shared.log(event: .adShowNoReady(placement))
      didFail?()
      return
    }
    guard wasLoadTimeGreaterThanInterval() else {
      LogManager.show(log: .ad, "[AppOpenAd] Display failure - Load time is less than interval! (\(placement))")
      didFail?()
      return
    }
    LogEventManager.shared.log(event: .adShowReady(placement))
    LogManager.show(log: .ad, "[AppOpenAd] Requested to show! (\(placement))")
    self.placement = placement
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    appOpenAd?.present(fromRootViewController: rootViewController)
  }
  
  func isTestMode() -> Bool? {
    guard
      let appOpenAd,
      let lineItems = appOpenAd.responseInfo.dictionaryRepresentation["Mediation line items"] as? [Any],
      let dictionary = lineItems.first as? [String: Any],
      let adSourceInstanceName = dictionary["Ad Source Instance Name"] as? String
    else {
      return nil
    }
    return adSourceInstanceName.lowercased().contains("test")
  }
}

extension AppOpenAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    if let placement {
      LogManager.show(log: .ad, "[AppOpenAd] Did fail to show content! (\(placement))")
      LogEventManager.shared.log(event: .adShowFail(placement, error))
    }
    didShowFail?()
    self.appOpenAd = nil
    load()
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    if let placement {
      LogManager.show(log: .ad, "[AppOpenAd] Will display! (\(placement))")
      LogEventManager.shared.log(event: .adShowSuccess(placement))
    }
    willPresent?()
    self.isShowing = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    if let placement {
      LogManager.show(log: .ad, "[AppOpenAd] Did hide! (\(placement))")
      LogEventManager.shared.log(event: .adShowHide(placement))
    }
    didHide?()
    self.appOpenAd = nil
    self.isShowing = false
    self.loadTime = Date()
    load()
  }
}

extension AppOpenAd {
  private func isReady() -> Bool {
    if !isExist(), retryAttempt >= 1 {
      load()
    }
    return isExist()
  }
  
  private func wasLoadTimeGreaterThanInterval() -> Bool {
    guard
      let loadTime = loadTime,
      let timeInterval = timeInterval
    else {
      return true
    }
    return Date().timeIntervalSince(loadTime) >= timeInterval
  }
  
  private func load() {
    guard !isLoading else {
      return
    }
    
    guard !isExist() else {
      return
    }
    
    guard let adUnitID = adUnitID else {
      LogManager.show(log: .ad, "[AppOpenAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      
      self.isLoading = true
      
      if let name {
        LogManager.show(log: .ad, "[AppOpenAd] Start load! (\(name))")
        LogEventManager.shared.log(event: .adLoadRequest(name))
        TimeManager.shared.start(event: .adLoad(.reuse(.appOpen), name))
      }
      let request = GADRequest()
      GADAppOpenAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self = self else {
          return
        }
        self.isLoading = false
        guard error == nil, let ad = ad else {
          self.retryAttempt += 1
          self.didLoadFail?()
          if let name {
            LogManager.show(log: .ad, "[AppOpenAd] Load fail (\(name)) - \(String(describing: error))!")
            LogEventManager.shared.log(event: .adLoadFail(name, error))
          }
          return
        }
        if let name {
          LogManager.show(log: .ad, "[AppOpenAd] Did load! (\(name))")
          let time = TimeManager.shared.end(event: .adLoad(.reuse(.appOpen), name))
          LogEventManager.shared.log(event: .adLoadSuccess(name, time))
        }
        self.retryAttempt = 0
        self.appOpenAd = ad
        self.appOpenAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        ad.paidEventHandler = { adValue in
          if let placement = self.placement {
            LogEventManager.shared.log(event: .adPayRevenue(placement))
            if adValue.value == 0 {
              LogEventManager.shared.log(event: .adNoRevenue(placement))
            }
          }
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AppOpen"
          ]
  
          // AppsFlyerAdRevenue.shared().logAdRevenue(
          //   monetizationNetwork: "admob",
          //   mediationNetwork: MediationNetworkType.googleAdMob,
          //   eventRevenue: adValue.value,
          //   revenueCurrency: adValue.currencyCode,
          //   additionalParameters: adRevenueParams)
          
          // AppsFlyerLib.shared().logEvent("ad_impression",
          //                                withValues: [
          //                                 AFEventParamRevenue: adValue.value,
          //                                 AFEventParamCurrency: adValue.currencyCode
          //                                ])
        }
      }
    }
  }
}
