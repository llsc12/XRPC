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

let xcodeWindowNames = [
    "Simulator",
    "Instruments",
    "Accessibility Inspector",
    "FileMerge",
    "Create ML",
    "RealityComposer",
]

class AXScrape: ObservableObject {
  var timer: Timer?
  init() {
    self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
      self.scrape()
    })
  }
    
  @Published var xcodeState: XcodeState? = nil
  
  func scrape() {
    guard UIElement.isProcessTrusted(withPrompt: false) else { return }
    
    guard let xcodeApp = Application.allForBundleID(xcodeBundleId).first else { self.xcodeState = nil; return }
    
    let focusedWindow: UIElement? = try? xcodeApp.attribute(.mainWindow)
    
    let windowTitle: String? = try? focusedWindow?.attribute(.title)
    let workspace: String? = windowTitle == nil ? nil : windowTitle!.components(separatedBy: " — ").first
    let isEditing: Bool = windowTitle?.contains("— Edited") ?? false
    let docFilePath: String? = try? focusedWindow?.attribute(.document)
    let doc: URL? = docFilePath == nil ? nil : URL(fileURLWithPath: docFilePath!.replacingOccurrences(of: "file://", with: ""))
    
    
    let xcState = XcodeState(
      workspace: workspace,
      editorFile: doc,
      isEditingFile: isEditing,
      sessionDate: self.xcodeState?.sessionDate ?? .now /// preserve xcode last date or make new date, used for timings
    )
    self.xcodeState = xcState
  }
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
    return editorFile?.lastPathComponent
  }
  
  var fileExtension: String? {
    if let fileName {
      let fx = fileName.split(separator: ".").last
      if let fx {
        return String(fx)
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
