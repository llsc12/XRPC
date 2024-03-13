//
//  SetupView.swift
//  XRPC
//
//  Created by Lakhan Lothiyi on 12/03/2024.
//

import SwiftUI
import AXSwift

class SetupVM: ObservableObject {
  static let shared = SetupVM()
  
  @Published var accessibilityAllowed: Bool = UIElement.isProcessTrusted(withPrompt: false)
  
  init() {
  }
  
  func accessibilityPrompt() {
    self.accessibilityAllowed = UIElement.isProcessTrusted(withPrompt: true)
  }
  
  var setupWindowClose: () -> Void = {}
  
}

struct SetupView: View {
  @ObservedObject var vm = SetupVM.shared
  var body: some View {
    VStack {
      VStack {
        Text("XRPC Setup")
          .font(.largeTitle)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .padding(.top)
        Spacer()
        
        List {
          HStack {
            Text("Accessibility")
            Spacer()
            if !vm.accessibilityAllowed {
              Button {
                vm.accessibilityPrompt()
              } label: {
                Text("Allow")
              }
            }
          }
        }
        .scrollContentBackground(.hidden)
        Button("Finish") {
          vm.setupWindowClose()
        }
      }
    }
    .frame(width: 300, height: 400)
    .background(.ultraThinMaterial)
  }
}
