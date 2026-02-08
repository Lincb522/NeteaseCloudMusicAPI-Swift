// UnblockView.swift
// 第三方解灰测试页面
// 支持添加/管理多种音源，测试解灰匹配和播放

import SwiftUI
import NeteaseCloudMusicAPI

struct UnblockView: View {
    @ObservedObject var vm: DemoViewModel

    var body: some View {
        List {
            // MARK: - 音源管理
            Section("音源配置") {
                // UNM 音源
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                        Text("UNM 音源")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $vm.unmEnabled)
                            .labelsHidden()
                    }
                    if vm.unmEnabled {
                        TextField("UNM 服务地址", text: $vm.unmServerUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .autocapitalization(.none)
                    }
                }

                // HTTP API 音源
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.green)
                        Text("HTTP API 音源")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $vm.httpApiEnabled)
                            .labelsHidden()
                    }
                    if vm.httpApiEnabled {
                        TextField("API 地址", text: $vm.httpApiServerUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .autocapitalization(.none)
                    }
                }

                // 洛雪音源
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "music.note.tv")
                            .foregroundColor(.purple)
                        Text("洛雪音源")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $vm.lxMusicEnabled)
                            .labelsHidden()
                    }
                    if vm.lxMusicEnabled {
                        TextField("洛雪 API 地址", text: $vm.lxMusicServerUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .autocapitalization(.none)
                    }
                }

                // 已注册音源数量
                HStack {
                    Text("已启用音源")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(vm.enabledSourceCount) 个")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }

            // MARK: - 音质选择
            Section("音质") {
                Picker("目标音质", selection: $vm.unblockQuality) {
                    Text("128kbps").tag("128")
                    Text("192kbps").tag("192")
                    Text("320kbps").tag("320")
                    Text("FLAC").tag("flac")
                }
                .pickerStyle(.segmented)
            }

            // MARK: - 单曲测试
            Section("单曲解灰测试") {
                HStack {
                    TextField("歌曲 ID", text: $vm.unblockSongId)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button {
                        Task { await vm.testUnblockSingle() }
                    } label: {
                        if vm.isUnblockLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                    }
                    .disabled(vm.isUnblockLoading || vm.enabledSourceCount == 0)
                }

                // 歌曲信息
                if !vm.unblockSongName.isEmpty {
                    HStack {
                        Image(systemName: "music.note")
                        Text(vm.unblockSongName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }

                // 匹配结果
                if let result = vm.unblockResult {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("匹配成功", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline.bold())
                        HStack {
                            Text("来源:")
                                .foregroundColor(.secondary)
                            Text(result.platform)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        HStack {
                            Text("音质:")
                                .foregroundColor(.secondary)
                            Text(result.quality)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        Text(result.url)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }

                if let err = vm.unblockError {
                    Label(err, systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // MARK: - 播放控制
            if vm.unblockResult != nil {
                Section("播放") {
                    HStack {
                        Button {
                            Task { await vm.playUnblockResult() }
                        } label: {
                            Label(
                                vm.isUnblockPlaying ? "正在播放" : "播放",
                                systemImage: vm.isUnblockPlaying ? "pause.circle.fill" : "play.circle.fill"
                            )
                        }
                        Spacer()
                        if vm.isUnblockPlaying {
                            Button("停止", role: .destructive) {
                                vm.stopUnblockPlaying()
                            }
                        }
                    }
                    if !vm.unblockPlayStatus.isEmpty {
                        Text(vm.unblockPlayStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - 全部音源测试
            Section("全部音源对比测试") {
                HStack {
                    TextField("歌曲 ID", text: $vm.unblockSongId)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button {
                        Task { await vm.testUnblockAll() }
                    } label: {
                        if vm.isUnblockAllLoading {
                            ProgressView()
                        } else {
                            Label("全部测试", systemImage: "list.bullet.rectangle")
                                .font(.caption)
                        }
                    }
                    .disabled(vm.isUnblockAllLoading || vm.enabledSourceCount == 0)
                }

                ForEach(Array(vm.unblockAllResults.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Image(systemName: item.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(item.success ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.sourceName)
                                .font(.subheadline.bold())
                            Text(item.detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(item.duration)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - 兼容旧接口测试
            Section("兼容接口测试") {
                // songUrlMatch
                Button {
                    Task { await vm.testSongUrlMatch() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                        VStack(alignment: .leading) {
                            Text("songUrlMatch (UNM)")
                                .font(.subheadline)
                            Text("兼容旧版 UNM 匹配接口")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if vm.isMatchLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(!vm.unmEnabled || vm.isMatchLoading)

                if !vm.matchResult.isEmpty {
                    Text(vm.matchResult)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // songUrlNcmget
                Button {
                    Task { await vm.testSongUrlNcmget() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                        VStack(alignment: .leading) {
                            Text("songUrlNcmget (HTTP API)")
                                .font(.subheadline)
                            Text("兼容旧版 GD Studio 接口")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if vm.isNcmgetLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(vm.isNcmgetLoading)

                if !vm.ncmgetResult.isEmpty {
                    Text(vm.ncmgetResult)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("解灰测试")
    }
}
