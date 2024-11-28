//
//  RPC.swift
//  XRPC
//
//  Created by Lakhan Lothiyi on 12/03/2024.
//

import Cocoa
import Foundation
import AXSwift
import SwordRPC
import Combine

fileprivate let RPC_CLIENT_ID = "1217178081484079135"

class RPC: ObservableObject, SwordRPCDelegate {
  static let shared = RPC()
  
  var rpc = SwordRPC(appId: RPC_CLIENT_ID)
  
  let scraper = AXScrape.init()
  
  var c = Set<AnyCancellable>()
  init() {
    scraper.objectWillChange.sink { _ in
      self.setPresence(self.scraper.presenceState)
    }.store(in: &c)
  }
  
  func initialCheck() {
    let axWorking = UIElement.isProcessTrusted(withPrompt: false)
    if axWorking == false {
      (NSApplication.shared.delegate as! AppDelegate).showSetupWindow()
    }
    rpcConnect()
  }
  
  @Published var rpcConnected: Bool = false
  func rpcConnect() {
    guard rpcConnected == false else { return }
    self.rpc = SwordRPC(appId: RPC_CLIENT_ID)
    self.rpc.delegate = self
    self.rpcConnected = self.rpc.connect()
  }
  
  func rpcDisconnect() {
    self.rpc.disconnect()
    self.rpcConnected = false
  }
  
  func swordRPCDidConnect(_ rpc: SwordRPC) {
    self.rpcConnected = true
  }
  
  func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
    self.rpcConnected = false
  }
  
  func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {
    print("[RPC Error] \(code) :: \(msg)")
    self.rpcDisconnect()
  }
  
  
  func setPresence(_ state: PresenceState) {
    switch state {
    case .xcodeNotRunning:    rpcDisconnect() /// disconnect to allow other rpcs to connect
    case .xcodeNoWindowsOpen: rpcDisconnect() /// disconnect since user isnt doing anything
    default:                  rpcConnect()    /// user is doing something, connect if not already connected
    }
    
    var presence = RichPresence()
    switch state {
    case .xcodeNotRunning: break
    case .xcodeNoWindowsOpen: break
    case .working(let xcodeState):
      if let ws = xcodeState.workspace {
        presence.details = "In \(ws)"
      }
      
      // if issues != 0
      var issuesString = ""
      if xcodeState.totalIssues != 0 {
        if xcodeState.errors != 0 {
          issuesString = "⛔️\(xcodeState.errors) "
        } else if xcodeState.warnings != 0 {
          issuesString = "⚠️\(xcodeState.totalIssues - xcodeState.errors) "
        }
      }
      
      if xcodeState.isIdle {
        presence.state = "Idling in Xcode"
      } else {
        if let filename = xcodeState.fileName {
          if xcodeState.isEditingFile {
            presence.state = "Editing \(filename) \(issuesString)"
          } else {
            presence.state = "Viewing \(filename) \(issuesString)"
          }
        }
      }
      
      let date = xcodeState.sessionDate ?? .now
      presence.timestamps.start = date
      presence.timestamps.end = nil
      
      presence.assets.largeImage = xcodeState.fileExtension ?? "xcode"
      presence.assets.largeText = presence.state
    case .isOnWelcome:
      presence.details = "In Welcome window"
      presence.state = "Choosing a project"
      
      presence.timestamps.start = nil
      presence.timestamps.end = nil
      
      presence.assets.largeImage = "xcode"
      presence.assets.largeText = "Welcome to Xcode"
    }
    rpc.setPresence(presence)
  }
}
