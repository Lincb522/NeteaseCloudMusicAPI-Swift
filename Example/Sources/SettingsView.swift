// SettingsView.swift
// 连接设置页面（iOS Form 风格）

import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: DemoViewModel

    var body: some View {
        Form {
            Section("服务模式") {
                TextField("后端地址（留空则直连）", text: $vm.serverUrl)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text(vm.serverUrl.isEmpty ? "当前: 直连网易云（客户端加密）" : "当前: 后端代理")
                    .font(.caption)
                    .foregroundStyle(vm.serverUrl.isEmpty ? .orange : .green)
            }

            Section("Cookie（可选）") {
                TextField("MUSIC_U=xxx; __csrf=xxx", text: $vm.cookie)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button("应用 Cookie") {
                    vm.applyCookie()
                }
            }

            Section("连接测试") {
                Button {
                    Task { await vm.testConnection() }
                } label: {
                    HStack {
                        Text("测试连接")
                        if vm.isLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(vm.isLoading)

                Text(vm.connectionStatus)
                    .font(.callout)

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("设置")
    }
}
