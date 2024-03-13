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
      self.setPresence(self.scraper.xcodeState)
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
  
  
  func setPresence(_ state: XcodeState?) {
    if state == nil { rpcDisconnect() } else { rpcConnect() }
    guard let state else { return }
    var presence = RichPresence()
    if let ws = state.workspace {
      presence.details = "In \(ws)"
    }
    
    if state.isIdle {
      presence.state = "Idling in Xcode"
    } else {
      if let filename = state.fileName {
        if state.isEditingFile {
          presence.state = "Editing \(filename)"
        } else {
          presence.state = "Viewing \(filename)"
        }
      }
    }
    
    let date = state.sessionDate ?? .now
    presence.timestamps.start = date
    presence.timestamps.end = nil
    
    presence.assets.largeImage = state.fileExtension ?? "xcode"
    presence.assets.largeText = presence.state
    
    rpc.setPresence(presence)
  }
}
