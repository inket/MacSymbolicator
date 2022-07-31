//
//  AppDelegate.swift
//  MacSymbolicator
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let mainController = MainController()

    func applicationDidFinishLaunching(_ notification: Notification) {}

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        mainController.openFile(filename)
    }
}
