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
    VStack(spacing: 15) {
      HStack {
        Image(systemName: vm.accessibilityAllowed ? "accessibility.fill" : "accessibility")
          .resizable()
          .foregroundStyle(.primary)
          .fontWeight(.light)
          .frame(width: 19, height: 19)
          .padding(5)
          .background(
            Circle()
              .fill(vm.accessibilityAllowed ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
          )
        LabeledContent {
          Spacer()
          Button {
            vm.accessibilityPrompt()
          } label: {
            Text("Allow")
          }
          .controlSize(.large)
          .disabled(vm.accessibilityAllowed)
        } label: {
          Text("Accessibility")
          Text(vm.accessibilityAllowed ? "Permission granted" : "Needs permission")
        }
      }
      Button {
        vm.setupWindowClose()
      } label: {
        Text("Finish")
          .frame(maxWidth: .infinity)
      }
      .controlSize(.large)
      .disabled(!vm.accessibilityAllowed)
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("XRPC Setup")
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }
    }
    .frame(minWidth: 300)
    .padding()
    .background(VisualEffectView().ignoresSafeArea())
  }
}

struct VisualEffectView: NSViewRepresentable {
  func makeNSView(context: Context) -> NSVisualEffectView {
    let effectView = NSVisualEffectView()
    effectView.state = .active
    return effectView
  }
  
  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
