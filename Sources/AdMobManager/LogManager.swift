//
//  Untitled.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 1/4/25.
//

import Foundation

class LogManager {
  enum Log: String {
    case ad = "Ad"
    case cmp = "CMP"
    case autoRelease = "AutoRelease"
    case tracking = "Tracking"
    case config = "Config"
    case api = "API"
    case event = "Event"
  }
  
  class func show(log: Log,
                  _ items: Any...,
                  separator: String = " ",
                  terminator: String = "\n",
                  file: String = #file,
                  function: String = #function,
                  line: Int = #line
  ) {
#if DEBUG
    let fileName = URL(fileURLWithPath: file).lastPathComponent
    let logLine = "[AdMobManager] [\(log.rawValue)] [\(fileName)] [\(line)] [\(function)]"
    print(logLine, items, separator: separator, terminator: terminator)
#endif
  }
}
