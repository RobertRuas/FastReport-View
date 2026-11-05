import SwiftUI

struct ProjectView: View {
    let state: AppState
    let project: Project

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ProjectPhotoBoardView(
                library: state.photoLibrary,
                dragState: state.photoDragState,
                isReportMode: state.isReportMode,
                isAutomationMode: state.isReportMode && state.isAutomationMode,
                automationIndex: state.automationIndex,
                onAdvanceAutomation: { state.advanceAutomation() },
                onRetreatAutomation: { state.retreatAutomation() }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                state.closeProject()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(IconActionButtonStyle())

            Text(project.displayName)
                .font(.title3.weight(.semibold))
            Spacer()
            if state.isReportMode {
                automationModeToggle
            }
            reportModeToggle
        }
        .padding(12)
    }

    private var reportModeToggle: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                state.isReportMode.toggle()
                if !state.isReportMode {
                    state.isAutomationMode = false
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: state.isReportMode ? "square.and.arrow.up.fill" : "arrow.left.arrow.right")
                Text(state.isReportMode ? "Modo de relatório" : "Organizar fotos")
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(state.isReportMode ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
            )
            .foregroundStyle(state.isReportMode ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
        .help(
            state.isReportMode
                ? "Modo de relatório ativo: arrastar uma foto a exporta para outro app. Clique para voltar a organizar."
                : "Organizando: arrastar reordena as fotos. Clique para ativar o modo de relatório e arrastar para fora do app."
        )
    }

    private var automationModeToggle: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                state.isAutomationMode.toggle()
                state.automationIndex = 0
            }
        } label: {
            Text("🤖")
                .font(.system(size: 13))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(state.isAutomationMode ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
        .help(
            state.isAutomationMode
                ? "Modo automação ativo: mostra um diretório por vez. ⌘→ avança, ⌘← volta. Clique para voltar à lista completa."
                : "Modo automação: mostra um diretório por vez com botões Anterior/Próximo (⌘←/⌘→) — para usar com um app de macro que automatiza cliques."
        )
    }
}
