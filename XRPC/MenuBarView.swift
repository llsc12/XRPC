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
    VStack {
      Text("XRPC")
        .font(.title)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, alignment: .leading)
      
      VStack(spacing: 10) {
        HStack {
          Text("RPC")
          Spacer()
          if rpc.rpcConnected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
          } else {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.red)
          }
        }
        
        HStack {
          Text("Xcode")
          Spacer()
          switch ax.presenceState {
          case .xcodeNotRunning:
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.red)
          default:
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
          }
        }
      }
      .frame(maxHeight: .infinity)
      
      Button("Quit") {
        exit(0)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(8)
  }
}
