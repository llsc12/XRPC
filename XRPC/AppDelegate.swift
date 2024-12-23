//
//  AppDelegate.swift
//  XRPC
//
//  Created by Lakhan Lothiyi on 12/03/2024.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var popover = NSPopover.init()
  var statusBar: StatusBarController?
  var window: NSWindow? = nil
  
  var rpc = RPC.shared

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Create the SwiftUI view that provides the contents
    let contentView = MenuBarView()
    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
    
    // Set the SwiftUI's ContentView to the Popover's ContentViewController
    popover.contentViewController = NSViewController()
    popover.contentSize = NSSize(width: 128, height: 128)
    popover.contentViewController?.view = NSHostingView(rootView: contentView)
    
    // Create the Status Bar Item with the Popover
    statusBar = StatusBarController.init(popover)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.rpc.initialCheck()
    }
  }
  
  func applicationDidBecomeActive(_ notification: Notification) {
    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
  }

  func popMenubarView() {
    guard let statusBar else { return }
    statusBar.hidePopover(nil)
  }
  
  func showMenubarView() {
    guard let statusBar else { return }
    statusBar.showPopover(nil)
  }
  
  func showSetupWindow() {
    let contentView = SetupView()
    let controller = KillOnCloseViewController()
    self.window = .init(contentViewController: controller)
    self.window?.styleMask = [
      .fullSizeContentView,
      .titled,
      .closable
    ]
    self.window?.contentViewController?.view = NSHostingView(rootView: contentView)
    self.window?.isMovableByWindowBackground = true
    self.window?.titlebarAppearsTransparent = true
    self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.window?.standardWindowButton(.zoomButton)?.isHidden = true
    self.window?.titleVisibility = .hidden
    self.window?.level = .floating
    self.window?.makeKeyAndOrderFront(self)
    self.window?.center()
    SetupVM.shared.setupWindowClose = { self.window?.close(); self.window = nil}
  }
  
}

class KillOnCloseViewController: NSViewController {
  override func viewDidAppear() {
    super.viewDidAppear()
  }
  
  override func viewDidDisappear() {
    guard SetupVM.shared.accessibilityAllowed else {
      exit(0)
    }
  }
}

class EventMonitor {
  private var monitor: Any?
  private let mask: NSEvent.EventTypeMask
  private let handler: (NSEvent?) -> Void
  
  public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
    self.mask = mask
    self.handler = handler
  }
  
  deinit {
    stop()
  }
  
  public func start() {
    monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as! NSObject
  }
  
  public func stop() {
    if monitor != nil {
      NSEvent.removeMonitor(monitor!)
      monitor = nil
    }
  }
}

class StatusBarController {
  private var statusBar: NSStatusBar
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  private var eventMonitor: EventMonitor?
  
  init(_ popover: NSPopover)
  {
    self.popover = popover
    statusBar = NSStatusBar.init()
    statusItem = statusBar.statusItem(withLength: 28.0)
    
    if let statusBarButton = statusItem.button {
      statusBarButton.image = .init(systemSymbolName: "hammer.fill", accessibilityDescription: "XRPC")
      statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
      statusBarButton.image?.isTemplate = true
      
      statusBarButton.action = #selector(togglePopover(sender:))
      statusBarButton.target = self
    }
    
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: mouseEventHandler)
  }
  
  @objc func togglePopover(sender: AnyObject) {
    if(popover.isShown) {
      hidePopover(sender)
    }
    else {
      showPopover(sender)
    }
  }
  
  func showPopover(_ sender: AnyObject?) {
    if let statusBarButton = statusItem.button {
      popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
      eventMonitor?.start()
    }
  }
  
  func hidePopover(_ sender: AnyObject?) {
    popover.performClose(sender)
    eventMonitor?.stop()
  }
  
  func mouseEventHandler(_ event: NSEvent?) {
    if(popover.isShown) {
      hidePopover(event!)
    }
  }
}
