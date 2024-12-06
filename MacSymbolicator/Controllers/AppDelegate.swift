//
//  AppDelegate.swift
//  MacSymbolicator
//

import Cocoa
import FullDiskAccess

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let mainController = MainController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Updates.availableUpdate(forUser: "inket", repository: "MacSymbolicator") { [weak self] release, error in
            if let release = release {
                self?.mainController.suggestUpdate(version: release.version.string, url: release.url)
            } else if let error = error {
                print("Error checking for updates: \(error)")
            }
        }

        FullDiskAccess.promptIfNotGranted(
            title: "Enable Full Disk Access for MacSymbolicator",
            message: "MacSymbolicator requires Full Disk Access to search for DSYMs using Spotlight.",
            canBeSuppressed: true
        )
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		DispatchQueue.main.async {
			_ = self.mainController.openFile(filename)
		}
		return true
    }
}
