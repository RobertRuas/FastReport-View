import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    let state: AppState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if state.projectsStore.projects.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
    }

    private var toolbar: some View {
        HStack {
            Text("Projetos")
                .font(.title3.weight(.semibold))
            Spacer()
            Button("Importar projeto (.zip)…", action: importProject)
        }
        .padding(12)
    }

    private var list: some View {
        List(state.projectsStore.projects) { project in
            HStack(spacing: 0) {
                Button {
                    state.open(project)
                } label: {
                    ProjectRow(project: project)
                }
                .buttonStyle(.plain)

                rowActions(for: project)
            }
        }
        .listStyle(.inset)
    }

    private func rowActions(for project: Project) -> some View {
        HStack(spacing: 4) {
            Button {
                state.projectsStore.setCompleted(project, !project.isCompleted)
            } label: {
                Image(systemName: project.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(IconActionButtonStyle(tint: .green))
            .foregroundStyle(project.isCompleted ? Color.green : Color.secondary)
            .help(project.isCompleted ? "Marcar como não concluído" : "Marcar como concluído")

            Button {
                renameProject(project)
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(IconActionButtonStyle())
            .foregroundStyle(.secondary)
            .help("Renomear")

            Button {
                deleteProject(project)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(IconActionButtonStyle(tint: .red))
            .foregroundStyle(.red)
            .help("Excluir")
        }
        .padding(.trailing, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("Sem projetos")
                .font(.title2.weight(.semibold))
            Text("Importa um projeto .zip para começar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func importProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let project = try ProjectImporter.importZip(at: url, into: state.projectsStore)
            state.open(project)
        } catch ProjectImportError.duplicateProject(let displayName) {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Projeto já importado"
            alert.informativeText = "O projeto \"\(displayName)\" já está na lista. Não foi importado novamente."
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Não foi possível importar o projeto"
            alert.informativeText = "Confirma que o .zip contém uma pasta de projeto do FastReport (com fastreport.json)."
            alert.runModal()
        }
    }

    private func renameProject(_ project: Project) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Renomear projeto"
        alert.addButton(withTitle: "Renomear")
        alert.addButton(withTitle: "Cancelar")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = project.displayName
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        if alert.runModal() == .alertFirstButtonReturn {
            let newName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newName.isEmpty else { return }
            state.projectsStore.rename(project, to: newName)
        }
    }

    private func deleteProject(_ project: Project) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Excluir \"\(project.displayName)\"?"
        alert.informativeText = "Esta ação remove o projeto da lista e apaga os seus ficheiros. Não pode ser desfeita."
        alert.addButton(withTitle: "Excluir")
        alert.addButton(withTitle: "Cancelar")

        if alert.runModal() == .alertFirstButtonReturn {
            state.projectsStore.remove(project)
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundStyle(project.isCompleted ? .tertiary : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.displayName)
                    .font(.body.weight(.medium))
                    .strikethrough(project.isCompleted)
                    .foregroundStyle(project.isCompleted ? .secondary : .primary)
                Text(project.importedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
