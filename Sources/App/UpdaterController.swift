import Foundation
import Sparkle

@Observable
final class UpdaterController {
    @ObservationIgnored
    private let standardController: SPUStandardUpdaterController

    @ObservationIgnored
    private var observation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false
    private(set) var lastCheckDate: Date?

    @ObservationIgnored
    private var lastCheckObservation: NSKeyValueObservation?

    let isAvailable = Bundle.main.bundleURL.pathExtension == "app"

    var automaticallyChecksForUpdates: Bool { standardController.updater.automaticallyChecksForUpdates }
    var automaticallyDownloadsUpdates: Bool { standardController.updater.automaticallyDownloadsUpdates }
    var checkIntervalHours: Int { Int(standardController.updater.updateCheckInterval / 3600) }
    var feedURLString: String? { standardController.updater.feedURL?.absoluteString }

    init() {
        standardController = SPUStandardUpdaterController(
            startingUpdater: Bundle.main.bundleURL.pathExtension == "app",
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        canCheckForUpdates = standardController.updater.canCheckForUpdates
        lastCheckDate = standardController.updater.lastUpdateCheckDate
        observation = standardController.updater.observe(\.canCheckForUpdates, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.canCheckForUpdates = change.newValue ?? false
            }
        }
        lastCheckObservation = standardController.updater.observe(\.lastUpdateCheckDate, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.lastCheckDate = change.newValue ?? nil
            }
        }
    }

    func checkForUpdates() {
        guard isAvailable else { return }
        standardController.checkForUpdates(nil)
    }
}
