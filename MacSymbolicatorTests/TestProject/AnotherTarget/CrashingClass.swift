//
//  CrashingClass.swift
//  AnotherTarget
//

import Foundation

@objc
public class CrashingClass: NSObject {
    @objc
    public static func crash() {
        NSException(name: .init(rawValue: "Crash"), reason: nil).raise()
    }
}
