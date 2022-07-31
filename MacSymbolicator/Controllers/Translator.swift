//
//  Translator.swift
//  MacSymbolicator
//

import Foundation

public enum Translator {
    enum Error: Swift.Error {
        case couldNotLoadOSAnalytics
        case couldNotFindClass
        case couldNotFindMethod
        case unexpectedOutput
    }

    /// Uses the private system framework OSAnalytics to perform the translation of the IPS crash report into
    /// the old-format crash report, the same way Console.app translates it.
    /// This is "hacky", but because we don't have any documentation for the IPS format, it's faster and less
    /// error-prone than manually parsing/translating IPS files ourselves. Obvious downside is that this
    /// method/class/framework could change in the future, but let's deal with that when it happens.
    public static func translatedCrash(forIPSAt path: URL) throws -> String {
        guard let bundle = Bundle(identifier: "com.apple.osanalytics.OSAnalytics") else {
            throw Error.couldNotLoadOSAnalytics
        }

        guard let klass = bundle.classNamed("OSALegacyXform") as? NSObject.Type else {
            throw Error.couldNotFindClass
        }

        let selector = NSSelectorFromString("transformURL:options:")

        guard klass.responds(to: selector) else {
            throw Error.couldNotFindMethod
        }

        let result = klass.perform(selector, with: path, with: [:]).takeUnretainedValue()

        guard
            let dictionary = result as? NSDictionary,
            let output = dictionary["symbolicated_log"] as? String,
            !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw Error.unexpectedOutput
        }

        return output
    }
}
