import AppKit
import SwiftUI

/// Modal simples de visualização de uma foto, apresentado como sheet a partir de
/// MainWindowView quando `AppState.previewPhoto` é definido (ao clicar numa miniatura).
/// Fecha no botão, no Esc (.cancelAction) ou ao clicar fora do sheet.
struct PhotoPreviewView: View {
    let photo: Photo
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            imageArea
        }
        .frame(minWidth: 520, idealWidth: 760, maxWidth: 1100,
               minHeight: 420, idealHeight: 620, maxHeight: 900)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(photo.url.lastPathComponent)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(IconActionButtonStyle())
            .keyboardShortcut(.cancelAction)
            .help("Fechar")
        }
        .padding(12)
    }

    private var imageArea: some View {
        Group {
            if let image = NSImage(contentsOf: photo.url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Não foi possível carregar a imagem")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
