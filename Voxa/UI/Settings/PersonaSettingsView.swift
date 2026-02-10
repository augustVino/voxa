//
//  PersonaSettingsView.swift
//  Voxa
//
//  Phase 4: 人设管理页 — 列表、CRUD、当前人设选择
//

import SwiftUI
import SwiftData

/// 人设设置：查看、新增、编辑、删除人设，选择当前人设
struct PersonaSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Persona.sortOrder) private var personas: [Persona]
    @AppStorage("activePersonaId") private var activePersonaId: String = ""
    @State private var showingAdd = false
    @State private var editingPersona: Persona?

    var body: some View {
        Form {
            // 操作栏 Section
            Section {
                HStack {
                    Spacer()
                    Button("添加人设", systemImage: "plus") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            // 人设列表 Section
            Section {
                ForEach(personas) { p in
                    PersonaRow(
                        persona: p,
                        isActive: activePersonaId == p.id,
                        onSelect: { setActivePersona(p) },
                        onEdit: { editingPersona = p },
                        onDelete: { deletePersona(p) }
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingAdd) {
            PersonaEditSheet(modelContext: modelContext, persona: nil) { showingAdd = false }
        }
        .sheet(item: $editingPersona) { p in
            PersonaEditSheet(modelContext: modelContext, persona: p) { editingPersona = nil }
        }
    }

    private func setActivePersona(_ p: Persona) {
        activePersonaId = p.id
    }

    private func deletePersona(_ p: Persona) {
        let wasActive = activePersonaId == p.id
        modelContext.delete(p)
        try? modelContext.save()

        // 如果删除的是当前激活的人设，自动选中内置人设
        // 内置人设始终存在（不可删除），所以无需检查
        if wasActive {
            activePersonaId = AppSettings.builtinDefaultPersonaID
        }
    }
}

// MARK: - 人设行
private struct PersonaRow: View {
    let persona: Persona
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 主行 - 使用 Button 包装以实现可靠的点击
            Button {
                onSelect()
            } label: {
                HStack {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(persona.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if persona.id == AppSettings.builtinDefaultPersonaID {
                                Text("内置")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        if !persona.descriptionText.isEmpty {
                            Text(persona.descriptionText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    // 操作按钮
                    HStack(spacing: 8) {
                        if persona.id == AppSettings.builtinDefaultPersonaID {
                            Button(isExpanded ? "收起" : "查看") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded.toggle()
                                }
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                            .accessibilityLabel(isExpanded ? "收起提示词" : "查看提示词")
                        } else {
                            Button("编辑", action: onEdit)
                                .controlSize(.small)
                                .buttonStyle(.bordered)
                                .accessibilityLabel("编辑人设")
                            Button("删除", role: .destructive, action: onDelete)
                                .controlSize(.small)
                                .buttonStyle(.bordered)
                                .accessibilityLabel("删除人设")
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(persona.name)
            .accessibilityHint(persona.id == AppSettings.builtinDefaultPersonaID ? "内置人设" : "自定义人设")
            .accessibilityAddTraits(isActive ? [.isSelected] : [])

            // 展开的提示词内容（仅内置人设）
            if persona.id == AppSettings.builtinDefaultPersonaID && isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    Text("提示词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(persona.prompt)
                        .font(.body)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .accessibilityLabel("提示词内容")
                    HStack {
                        Spacer()
                        Button("复制") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(persona.prompt, forType: .string)
                        }
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                        .accessibilityLabel("复制提示词")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("提示词详情")
            }
        }
    }
}

// MARK: - 人设编辑表单
struct PersonaEditSheet: View {
    let modelContext: ModelContext
    let persona: Persona?
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var prompt = ""
    @State private var descriptionText = ""

    var body: some View {
        Form {
            TextField("名称", text: $name)
            TextField("润色 Prompt", text: $prompt, axis: .vertical)
                .lineLimit(3...8)
            TextField("描述（可选）", text: $descriptionText, axis: .vertical)
                .lineLimit(1...3)
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            if let p = persona {
                name = p.name
                prompt = p.prompt
                descriptionText = p.descriptionText
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onDismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                    onDismiss()
                }
                .disabled(name.isEmpty || prompt.isEmpty)
            }
        }
    }

    private func save() {
        if let p = persona {
            p.name = name
            p.prompt = prompt
            p.descriptionText = descriptionText
            p.updatedAt = Date()
        } else {
            let p = Persona(name: name, prompt: prompt, descriptionText: descriptionText)
            modelContext.insert(p)
        }
        try? modelContext.save()
    }
}

#Preview {
    PersonaSettingsView()
        .modelContainer(for: [Persona.self], inMemory: true)
}
