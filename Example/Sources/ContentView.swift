// ContentView.swift
// 主界面 - 标签页导航（iOS 底部 Tab Bar）

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = DemoViewModel()

    var body: some View {
        TabView {
            // 搜索歌曲
            NavigationStack {
                SearchView(vm: vm)
            }
            .tabItem { Label("搜索", systemImage: "magnifyingglass") }

            // 歌单广场
            NavigationStack {
                PlaylistView(vm: vm)
            }
            .tabItem { Label("歌单", systemImage: "music.note.list") }

            // 排行榜
            NavigationStack {
                ToplistView(vm: vm)
            }
            .tabItem { Label("排行榜", systemImage: "chart.bar") }

            // 电台
            NavigationStack {
                DJRadioView(vm: vm)
            }
            .tabItem { Label("电台", systemImage: "radio") }

            // 连接设置
            NavigationStack {
                SettingsView(vm: vm)
            }
            .tabItem { Label("设置", systemImage: "gear") }
        }
    }
}
