//
//  AXScrape.swift
//  XRPC
//
//  Created by Lakhan Lothiyi on 13/03/2024.
//

import Foundation
import AXSwift
import Cocoa
import SwordRPC

let xcodeBundleId = "com.apple.dt.Xcode"

class AXScrape: ObservableObject {
  var timer: Timer?
  init() {
    self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { _ in
      self.scrape()
    })
  }
  
  @Published var presenceState: PresenceState = .xcodeNoWindowsOpen
  
  func scrape() {
    guard UIElement.isProcessTrusted(withPrompt: false) else { return }
    
    let xcodeProcess = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == xcodeBundleId }
    guard let xcodeApp = Application.allForBundleID(xcodeBundleId).first else { self.presenceState = .xcodeNotRunning; return }
    
    let windows = try? xcodeApp.windows()
    
    let mainWindow: UIElement? = try? xcodeApp.attribute(.mainWindow)
    
    let focusedWindow: UIElement? = try? xcodeApp.attribute(.focusedWindow)
    let focusedWindowTitle: String? = try? focusedWindow?.attribute(.title)
    
    if mainWindow == nil && (windows?.isEmpty ?? false) {
      // no windows open
      self.presenceState = .xcodeNoWindowsOpen
    }
    
    if focusedWindowTitle?.contains("Welcome") ?? false {
      self.presenceState = .isOnWelcome
      return
    }
    
    let windowTitle: String? = try? mainWindow?.attribute(.title)
    let workspace: String? = windowTitle == nil ? nil : windowTitle!.components(separatedBy: " — ").first
    let isEditing: Bool = windowTitle?.contains("— Edited") ?? false
    let docFilePath: String? = try? mainWindow?.attribute(.document)
    let doc: URL? = docFilePath == nil ? nil : URL(fileURLWithPath: docFilePath!.replacingOccurrences(of: "file://", with: ""))
    
    let currentSessionDate: Date? = {
      switch presenceState {
      case .working(let xcodeState):
        return xcodeState.sessionDate
      default: return nil
      }
    }()
    
    let xcState = XcodeState(
      workspace: workspace,
      editorFile: doc,
      isEditingFile: isEditing,
      sessionDate: currentSessionDate ?? xcodeProcess?.launchDate ?? .now /// preserve xcode last date or make new date, used for timings
    )
    
    
    
    self.presenceState = .working(xcState)
  }
}

enum PresenceState {
  case xcodeNotRunning
  case xcodeNoWindowsOpen // when xcode has no windows and is doing nothing
  case working(XcodeState) // when user is working
  case isOnWelcome
}

struct XcodeState: Equatable {
  var workspace: String?
  var editorFile: URL?
  var isEditingFile: Bool
  
  var sessionDate: Date?
  
  /// Is true if xcode has no file open (sitting in xcodeproj or xcworkspace)
  var isIdle: Bool {
    editorFile?.lastPathComponent.contains("xcodeproj") ?? true || editorFile?.lastPathComponent.contains("xcworkspace") ?? true
  }
  
  var fileName: String? {
    if isIdle { return nil }
    return editorFile?.lastPathComponent.removingPercentEncoding
  }
  
  var fileExtension: String? {
    if let fileName {
      let fx = fileName.split(separator: ".").last
      if let fx {
        return String(fx).lowercased()
      }
    }
    return nil
  }
}




fileprivate extension String {
  func numberOfOccurrencesOf(string: String) -> Int {
    self.components(separatedBy: string).count - 1
  }
}
