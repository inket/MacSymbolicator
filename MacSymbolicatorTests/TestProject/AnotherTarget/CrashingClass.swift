//
//  CrashingClass.swift
//  AnotherTarget
//

import Foundation

@objc
public class CrashingClass: NSObject {
    @objc
    public static func crash() {
        fatalError("Crashed in AnotherTarget")
    }
}
