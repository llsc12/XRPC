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
      if case .working(let xcodeState) = presenceState {
        return xcodeState.sessionDate
      }
      return nil
    }()
    
    var warnings: Int, errors: Int, issues: Int
    warnings = 0
    errors = 0
    issues = 0
    
    // we need to get the ui elements for the header bar of xcode since thats where the warns and errors are displayed
    if
      let focusedWindow,
      let sourceEditor = filterElements(of: focusedWindow, filter: {
        (try? $0.role()) ?? .unknown == .textArea &&
        (try? $0.attribute(.description) ?? "") == "Source Editor"
      }).first
      
    {
      // editor shows errors, runtime warnings and warnings etc in "Line Annotation" id'd elements
      let annotations = filterElements(of: sourceEditor, filter: {
        (try? $0.role()) ?? .unknown == .button &&
        (try? $0.attribute(.identifier)) == "Line Annotation"
      })
      
      for annotation in annotations {
        issues += 1
        let line = ((try? annotation.attribute(.description) ?? "") ?? "")
        if line.starts(with: "Warning") && line.contains("Runtime Issue") {
          warnings += 1
        } else if line.starts(with: "Warning") {
          warnings += 1
        } else if line.starts(with: "Error") {
          errors += 1
        }
      }
    }
    
    let xcState = XcodeState(
      workspace: workspace,
      editorFile: doc,
      isEditingFile: isEditing,
      sessionDate: currentSessionDate ?? xcodeProcess?.launchDate ?? .now, /// preserve xcode last date or make new date, used for timings
      errors: errors,
      warnings: warnings,
      totalIssues: issues
    )
    
    
    
    self.presenceState = .working(xcState)
  }
}

enum PresenceState: Equatable {
  case xcodeNotRunning
  case xcodeNoWindowsOpen // when xcode has no windows and is doing nothing
  case working(XcodeState) // when user is working
  case isOnWelcome
  
  var displayName: String {
    switch self {
    case .xcodeNotRunning:
      return "Not open"
    case .xcodeNoWindowsOpen:
      return "No active window"
    case .working:
      return "Working on a project"
    case .isOnWelcome:
      return "In the welcome screen"
    }
  }
}

struct XcodeState: Equatable {
  var workspace: String?
  var editorFile: URL?
  var isEditingFile: Bool
  
  var sessionDate: Date?
  
  var errors: Int
  var warnings: Int
  var totalIssues: Int
  
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


func traverseHierarchy(of element: UIElement, level: Int = 0) {
  let indent = String(repeating: "  ", count: level)
  
  // Log the current (parent) element's details
  do {
    let role = try element.attribute(.role) as String? ?? "Unknown"
    let title = try element.attribute(.title) as String? ?? "No Title"
    let help = try element.attribute(.help) as String? ?? "No Help"
    let desc = try element.attribute(.description) as String? ?? "No Description"
    let vald = try element.attribute(.valueDescription) as String? ?? "No Value Description"
    
    //    print("\(indent)- [\(role) name] \(title)")
    //    print("\(indent)- [\(role) help] \(help)")
    //    print("\(indent)- [\(role) desc] \(desc)")
    //    print("\(indent)- [\(role) vald] \(vald)")
    print("\(indent)- [\(role)] \(try! element.getMultipleAttributes(element.attributes()).map {($0.key.rawValue, $0.value)})")
    print("")
    
//    Any as String
  } catch {
    print("\(indent)- Error accessing attributes for element: \(error)")
  }
  
  // Get the children of the current element
  if let children = try? element.children() {
    for child in children {
      // Recursive call to traverse and log children
      traverseHierarchy(of: child, level: level + 1)
    }
  }
}

extension UIElement {
  func children() throws -> [UIElement] {
    let a: [AXUIElement] = (try attribute(.children)) ?? [AXUIElement]()
    return a.map { UIElement($0) }
  }
}

/// Recursively traverses the accessibility hierarchy and applies a closure to filter elements.
///
/// - Parameters:
///   - element: The root `UIElement` to start the traversal from.
///   - level: The current depth in the hierarchy (used for indentation/debugging purposes).
///   - filter: A closure that takes a `UIElement` and returns a `Bool`. If the closure returns `true`, the element is considered a match.
/// - Returns: A list of `UIElement` objects that match the filter condition.
func filterElements(
  of element: UIElement,
  level: Int = 0,
  filter: (UIElement) -> Bool
) -> [UIElement] {
  var matchingElements = [UIElement]()
  
  // Check if the current element matches the filter
  if filter(element) {
    matchingElements.append(element)
  }
  
  // Recursively traverse the children of the element
  if let children = try? element.children() {
    for child in children {
      let childMatches = filterElements(of: child, level: level + 1, filter: filter)
      matchingElements.append(contentsOf: childMatches)
    }
  }
  
  return matchingElements
}
