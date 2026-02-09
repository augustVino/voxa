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
    @State private var settings = AppSettings.shared
    @State private var showingAdd = false
    @State private var editingPersona: Persona?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("添加人设") { showingAdd = true }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .background(.regularMaterial)
            personaList
                .overlay { personaEmptyOverlay }
        }
        .sheet(isPresented: $showingAdd) {
                PersonaEditSheet(modelContext: modelContext, persona: nil) { showingAdd = false }
            }
            .sheet(item: $editingPersona) { p in
                PersonaEditSheet(modelContext: modelContext, persona: p) { editingPersona = nil }
            }
    }

    private var personaList: some View {
        List {
            ForEach(personas) { p in
                PersonaRow(
                    persona: p,
                    isActive: settings.activePersonaId == p.id,
                    onSelect: { setActivePersona(p) },
                    onEdit: { editingPersona = p },
                    onDelete: { deletePersona(p) }
                )
            }
        }
    }

    @ViewBuilder
    private var personaEmptyOverlay: some View {
        if personas.isEmpty {
            ContentUnavailableView("暂无人设", systemImage: "person.crop.circle.badge.plus", description: Text("点击上方「添加人设」创建"))
        }
    }

    private func setActivePersona(_ p: Persona) {
        settings.activePersonaId = p.id
    }

    private func deletePersona(_ p: Persona) {
        if settings.activePersonaId == p.id {
            settings.activePersonaId = ""
        }
        modelContext.delete(p)
        try? modelContext.save()
    }
}

// MARK: - 人设行
private struct PersonaRow: View {
    let persona: Persona
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(persona.name)
                    .font(.headline)
                if !persona.descriptionText.isEmpty {
                    Text(persona.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("编辑", action: onEdit)
            Button("删除", role: .destructive, action: onDelete)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
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
