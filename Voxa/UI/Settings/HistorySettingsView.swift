//
//  HistorySettingsView.swift
//  Voxa
//
//  Phase 4: 历史记录页 — 仅 30 天内、搜索、复制、删除
//

import SwiftUI
import SwiftData

private var historyRetentionDays: Int { InputHistoryCleanup.retentionDays }

/// 历史记录设置：仅展示最近 30 天内记录，支持搜索、复制、单条/批量删除
struct HistorySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    private var cutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -historyRetentionDays, to: Date()) ?? Date()
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索历史记录", text: $searchText)
                        .textFieldStyle(.plain)
                }
            }

            Section {
                HistoryListContent(
                    modelContext: modelContext,
                    cutoffDate: cutoffDate,
                    searchText: searchText
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .safeAreaInset(edge: .bottom) {
            Text("仅保留最近 \(historyRetentionDays) 天")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// 历史记录列表内容：支持搜索过滤、多选、批量操作
struct HistoryListContent: View {
    let modelContext: ModelContext
    let cutoffDate: Date
    let searchText: String
    @State private var items: [InputHistory] = []
    @State private var selectedIds: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // 批量操作栏
            if !selectedIds.isEmpty {
                HStack {
                    Text("已选 \(selectedIds.count) 条")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("删除选中", role: .destructive) {
                        deleteSelected()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }

            List(selection: $selectedIds) {
                ForEach(filteredItems) { item in
                    HistoryRow(item: item, onCopy: { copyItem(item) }, onDelete: { deleteItem(item) })
                        .tag(item.id)
                }
            }
            .listStyle(.plain)
            .onAppear { loadItems() }
            .onChange(of: searchText) { _, _ in loadItems() }
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView("暂无历史记录", systemImage: "clock.arrow.circlepath", description: Text("最近 30 天内的语音输入将显示在这里"))
                }
            }
        }
    }

    private var filteredItems: [InputHistory] {
        if searchText.isEmpty { return items }
        let lower = searchText.lowercased()
        return items.filter {
            $0.rawText.lowercased().contains(lower) || $0.processedText.lowercased().contains(lower)
        }
    }

    private func loadItems() {
        var d = FetchDescriptor<InputHistory>(
            predicate: #Predicate<InputHistory> { $0.createdAt >= cutoffDate }
        )
        d.sortBy = [SortDescriptor<InputHistory>(\.createdAt, order: .reverse)]
        items = (try? modelContext.fetch(d)) ?? []
    }

    private func copyItem(_ item: InputHistory) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.processedText, forType: .string)
    }

    private func deleteItem(_ item: InputHistory) {
        modelContext.delete(item)
        try? modelContext.save()
        items.removeAll { $0.id == item.id }
    }

    private func deleteSelected() {
        for id in selectedIds {
            if let item = items.first(where: { $0.id == id }) {
                modelContext.delete(item)
            }
        }
        try? modelContext.save()
        selectedIds.removeAll()
        loadItems()
    }
}

struct HistoryRow: View {
    let item: InputHistory
    let onCopy: () -> Void
    let onDelete: () -> Void

    private var summary: String {
        let s = item.processedText
        return s.count > 80 ? String(s.prefix(80)) + "…" : s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary)
                .lineLimit(2)
            HStack {
                if let name = item.personaName, !name.isEmpty {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(item.duration))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("复制", action: onCopy)
                    .controlSize(.small)
                Button("删除", role: .destructive, action: onDelete)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistorySettingsView()
        .modelContainer(for: [InputHistory.self], inMemory: true)
}
