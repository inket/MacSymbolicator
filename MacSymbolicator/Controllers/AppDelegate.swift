//
//  AppDelegate.swift
//  MacSymbolicator
//

import Cocoa
import Squirrel

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let mainController = MainController()
    var updater: SQRLUpdater?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "disableSquirrel") == false {
            setupUpdater()
        }
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return mainController.openFile(filename)
    }

    func setupUpdater() {
        guard let bundleVersion = Bundle.main.sqrl_bundleVersion.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else {
            assertionFailure()
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "tars.mahdi.jp"
        components.path = "/squirrel/macsymbolicator/\(bundleVersion)"

        guard let updateURL = components.url else {
            assertionFailure()
            return
        }
        updater = SQRLUpdater(update: URLRequest(url: updateURL))
        updater?.startAutomaticChecks(withInterval: 60)
    }
}
