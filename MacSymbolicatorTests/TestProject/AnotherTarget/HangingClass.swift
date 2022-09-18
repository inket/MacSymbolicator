//
//  HangingClass.swift
//  AnotherTarget
//

import Foundation

@objc
public class HangingClass: NSObject {
    @objc
    public static func hang() {
        DispatchQueue.global().async {
            sleep(3600)
        }
    }
}
