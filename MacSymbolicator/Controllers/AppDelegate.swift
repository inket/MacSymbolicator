//
//  AppDelegate.swift
//  MacSymbolicator
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let mainController = MainController()

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return mainController.openFile(filename)
    }
}
