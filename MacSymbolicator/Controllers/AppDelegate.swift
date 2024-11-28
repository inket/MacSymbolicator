//
//  AppDelegate.swift
//  MacSymbolicator
//

import Cocoa
import FullDiskAccess

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    var controllers: [DocumentController] = []

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if controllers.isEmpty {
            controllers.append(DocumentController(reportFile: nil, index: 0, delegate: self))
        }

//        Updates.availableUpdate(forUser: "inket", repository: "MacSymbolicator") { [weak self] release, error in
//            if let release = release {
//                self?.mainController.suggestUpdate(version: release.version.string, url: release.url)
//            } else if let error = error {
//                print("Error checking for updates: \(error)")
//            }
//        }

//        FullDiskAccess.promptIfNotGranted(
//            title: "Enable Full Disk Access for MacSymbolicator",
//            message: "MacSymbolicator requires Full Disk Access to search for dSYMs using Spotlight.",
//            canBeSuppressed: true
//        )
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let fileURLs = filenames.map { path in URL(fileURLWithPath: path) }

        if openFiles(fileURLs) {
            NSApp.reply(toOpenOrPrint: .success)
        } else {
            NSApp.reply(toOpenOrPrint: .failure)
        }
    }

    func openFiles(_ fileURLs: [URL]) -> Bool {
        var openedSomeFiles: Bool = false

        for fileURL in fileURLs {
            if let reportFile = try? ReportFile(path: fileURL) {
                var assignedToAController: Bool = false

                for controller in controllers {
                    switch controller.acceptReportFile(reportFile) {
                    case .openedOk:
                        openedSomeFiles = true
                        assignedToAController = true
                    case .alreadyOpen:
                        controller.orderFront()
                        assignedToAController = true
                    case .notNeeded:
                        assignedToAController = false
                    }

                    if assignedToAController {
                        break
                    }
                }

                if !assignedToAController {
                    controllers.append(
                        DocumentController(
                            reportFile: reportFile,
                            index: controllers.count,
                            delegate: self
                        )
                    )
                }

                openedSomeFiles = true
            }
        }

        let dsymFiles = fileURLs.flatMap { DSYMFile.dsymFiles(from: $0) }
        for controller in controllers {
            if controller.acceptDSYMFiles(dsymFiles) {
                openedSomeFiles = true
            }
        }

        return openedSomeFiles
    }
}

// MARK: - DocumentControllerDelegate

extension AppDelegate: DocumentControllerDelegate {
    func documentControllerWillClose(_ documentController: DocumentController) {
        controllers.removeAll { $0 === documentController }
    }
}
