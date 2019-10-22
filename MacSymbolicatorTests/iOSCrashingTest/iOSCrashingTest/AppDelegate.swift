//
//  AppDelegate.swift
//  iOSCrashingTest
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        CrashClass.pleaseCrash()
    }
}

class CrashClass {
    @inline(never) // Or else the compiler will optimize this method into viewDidLoad
    static func pleaseCrash() {
        print("Crashing…")
        fatalError("Here's the crash")
    }
}
