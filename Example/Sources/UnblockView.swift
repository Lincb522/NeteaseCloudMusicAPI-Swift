// UnblockView.swift
// 第三方解灰测试页面
// 支持导入 JS 音源脚本和自定义音源地址

import SwiftUI
import NeteaseCloudMusicAPI
import UniformTypeIdentifiers

struct UnblockView: View {
    @ObservedObject var vm: DemoViewModel

    var body: some View {
        List {
            // MARK: - 音源管理
            Section {
                // 导入 JS 音源
                Button {
                    vm.showJSFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("导入 JS 音源脚本")
                                .font(.subheadline)
                            Text("支持洛雪音乐助手格式的 .js 音源文件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 添加自定义地址
                Button {
                    vm.showAddURLSource = true
                } label: {
                    HStack {
                        Image(systemName: "link.badge.plus")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("添加自定义音源地址")
                                .font(.subheadline)
                            Text("输入 HTTP API 地址，支持多种接口格式")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("添加音源")
            }

            // MARK: - 已添加的音源列表
            if !vm.unblockSources.isEmpty {
                Section {
                    ForEach(Array(vm.unblockSources.enumerated()), id: \.offset) { index, source in
                        HStack {
                            Image(systemName: source.type == .jsScript ? "doc.text" : "link")
                                .foregroundColor(source.type == .jsScript ? .orange : .blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.name)
                                    .font(.subheadline.bold())
                                Text(source.type == .jsScript ? "JS 脚本音源" : source.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { source.enabled },
                                set: { vm.unblockSources[index].enabled = $0 }
                            ))
                            .labelsHidden()
                        }
                    }
                    .onDelete { indexSet in
                        vm.unblockSources.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        vm.unblockSources.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    HStack {
                        Text("已添加音源（\(vm.enabledSourceCount) 个启用）")
                        Spacer()
                        EditButton()
                            .font(.caption)
                    }
                } footer: {
                    Text("拖动排序调整优先级，靠前的优先使用。左滑删除。")
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

                if !vm.unblockSongName.isEmpty {
                    HStack {
                        Image(systemName: "music.note")
                        Text(vm.unblockSongName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }

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

            // MARK: - 全部音源对比
            Section("全部音源对比测试") {
                Button {
                    Task { await vm.testUnblockAll() }
                } label: {
                    HStack {
                        if vm.isUnblockAllLoading {
                            ProgressView()
                        } else {
                            Label("测试全部启用音源", systemImage: "list.bullet.rectangle")
                        }
                        Spacer()
                        Text("\(vm.enabledSourceCount) 个音源")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(vm.isUnblockAllLoading || vm.enabledSourceCount == 0)

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
        }
        .navigationTitle("解灰测试")
        .sheet(isPresented: $vm.showJSFilePicker) {
            JSFilePickerView(vm: vm)
        }
        .sheet(isPresented: $vm.showAddURLSource) {
            AddURLSourceView(vm: vm)
        }
    }
}

// MARK: - JS 文件选择器

struct JSFilePickerView: View {
    @ObservedObject var vm: DemoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("导入 JS 音源脚本")
                    .font(.title2.bold())

                Text("选择洛雪音乐助手格式的 .js 音源文件。\n脚本需导出 getUrl(songId, quality) 函数。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 手动粘贴 JS 代码
                VStack(alignment: .leading, spacing: 8) {
                    Text("或直接粘贴 JS 代码：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $vm.jsScriptInput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("选择文件") {
                        showFilePicker = true
                    }
                    .buttonStyle(.bordered)

                    Button("导入代码") {
                        vm.importJSFromText()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.jsScriptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "js") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    vm.importJSFromFile(url: url)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 添加自定义地址

struct AddURLSourceView: View {
    @ObservedObject var vm: DemoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sourceName = ""
    @State private var sourceURL = ""
    @State private var useTemplate = false
    @State private var urlTemplate = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("音源信息") {
                    TextField("音源名称", text: $sourceName)
                    TextField("API 地址", text: $sourceURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section {
                    Toggle("使用自定义 URL 模板", isOn: $useTemplate)
                    if useTemplate {
                        TextField("URL 模板", text: $urlTemplate)
                            .autocapitalization(.none)
                            .font(.system(.caption, design: .monospaced))
                        Text("占位符: {id} = 歌曲ID, {quality} = 音质, {baseURL} = API地址")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("高级")
                } footer: {
                    Text("默认格式: {baseURL}?types=url&id={id}&br={quality}")
                }

                Section {
                    Text("常见格式示例：")
                        .font(.caption.bold())
                    Group {
                        Text("• 标准格式: https://api.example.com/api.php")
                        Text("• UNM 格式: http://localhost:8080/match")
                        Text("• 洛雪格式: http://localhost:9763/url/wy/{id}/{quality}")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加音源地址")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let template = useTemplate ? urlTemplate : nil
                        vm.addURLSource(name: sourceName, url: sourceURL, template: template)
                        dismiss()
                    }
                    .disabled(sourceName.isEmpty || sourceURL.isEmpty)
                }
            }
        }
    }
}
