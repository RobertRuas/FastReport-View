import AppKit
import Sparkle

final class SilentUpdateUserDriver: NSObject, SPUUserDriver {
    private let minimumVisibleDuration: TimeInterval = 5

    private var progressWindow: UpdateProgressWindow?
    private var downloadStartDate: Date?
    private var expectedContentLength: UInt64 = 0
    private var receivedContentLength: UInt64 = 0
    private var isUserInitiatedCheck = false

    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
        reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
    }

    func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        isUserInitiatedCheck = true
    }

    func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
        reply(.install)
    }

    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {}

    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {}

    func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        if isUserInitiatedCheck {
            presentAlert(title: "Nenhuma atualização encontrada", message: "A aplicação já está na versão mais recente.")
        }
        isUserInitiatedCheck = false
        acknowledgement()
    }

    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        progressWindow?.close()
        progressWindow = nil
        downloadStartDate = nil
        if isUserInitiatedCheck {
            presentAlert(title: "Não foi possível atualizar", message: error.localizedDescription)
        }
        isUserInitiatedCheck = false
        acknowledgement()
    }

    func showDownloadInitiated(cancellation: @escaping () -> Void) {
        downloadStartDate = Date()
        expectedContentLength = 0
        receivedContentLength = 0

        let window = progressWindow ?? UpdateProgressWindow()
        progressWindow = window
        window.setStatus("A transferir atualização…")
        window.setIndeterminate(true)
        window.setProgress(0)
        window.show()
    }

    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        self.expectedContentLength = expectedContentLength
        progressWindow?.setIndeterminate(expectedContentLength == 0)
    }

    func showDownloadDidReceiveData(ofLength length: UInt64) {
        receivedContentLength += length
        guard expectedContentLength > 0 else { return }
        let fraction = Double(receivedContentLength) / Double(expectedContentLength)
        progressWindow?.setProgress(fraction * 0.9)
    }

    func showDownloadDidStartExtractingUpdate() {
        progressWindow?.setStatus("A instalar atualização…")
        progressWindow?.setIndeterminate(false)
        progressWindow?.setProgress(0.9)
    }

    func showExtractionReceivedProgress(_ progress: Double) {
        progressWindow?.setProgress(0.9 + progress * 0.1)
    }

    func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        progressWindow?.setStatus("A reiniciar a aplicação…")
        progressWindow?.setProgress(1)
        waitForMinimumVisibleDuration { reply(.install) }
    }

    func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {
        progressWindow?.setStatus("A instalar atualização…")
    }

    func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        progressWindow?.close()
        progressWindow = nil
        downloadStartDate = nil
        acknowledgement()
    }

    func dismissUpdateInstallation() {
        progressWindow?.close()
        progressWindow = nil
        downloadStartDate = nil
        isUserInitiatedCheck = false
    }

    private func waitForMinimumVisibleDuration(then completion: @escaping () -> Void) {
        guard let downloadStartDate else {
            completion()
            return
        }
        let remaining = minimumVisibleDuration - Date().timeIntervalSince(downloadStartDate)
        guard remaining > 0 else {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: completion)
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
