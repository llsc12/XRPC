//
//  MenuBarView.swift
//  XRPC
//
//  Created by Lakhan Lothiyi on 12/03/2024.
//

import SwiftUI

struct MenuBarView: View {
  @ObservedObject var rpc = RPC.shared
  @ObservedObject var ax = RPC.shared.scraper
  
  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          MenuBarStatusView(
            for: rpc.rpcConnected,
            offIf: false
          ) {
            Image(systemName: "text.page")
          } disabled: {
            Image(systemName: "text.page.slash")
          }
          LabeledContent(content: {}, label: {
            Text("RPC")
            Text(rpc.rpcConnected ? "Active" : "Inactive")
          })
        }
        
        HStack {
          MenuBarStatusView(
            for: ax.presenceState,
            offIf: .xcodeNotRunning
          ) {
            Image(systemName: "hammer")
          } disabled: {
            Image(systemName: "hammer")
          }
          LabeledContent(content: {}, label: {
            Text("Xcode")
            Text(ax.presenceState.displayName)
          })
        }
      }
      
      Button {
        exit(0)
      } label: {
        Text("Quit")
          .frame(maxWidth: .infinity)
      }
      .controlSize(.large)
    }
    .frame(minWidth: 275)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(12)
  }
}

struct MenuBarStatusView<State: Equatable, EnabledContent: View, DisabledContent: View>: View {
  var state: State
  var disabledState: State
  var enabledContent: () -> EnabledContent
  var disabledContent: () -> DisabledContent
  
  init(
    for state: State,
    offIf disabledState: State,
    @ViewBuilder _ enabled: @escaping () -> EnabledContent,
    @ViewBuilder disabled: @escaping () -> DisabledContent
  ) {
    self.state = state
    self.disabledState = disabledState
    self.enabledContent = enabled
    self.disabledContent = disabled
  }
  
  var body: some View {
    if state != disabledState {
      enabledContent()
        .foregroundStyle(.white)
        .frame(width: 14, height: 14)
        .padding(8)
        .background(
          Circle()
            .fill(.tint)
        )
    } else {
      disabledContent()
        .foregroundStyle(.white)
        .frame(width: 14, height: 14)
        .padding(8)
        .background(
          Circle()
            .fill(.quaternary)
        )
    }
  }
}
