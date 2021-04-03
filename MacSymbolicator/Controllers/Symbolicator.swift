//
//  Symbolicator.swift
//  MacSymbolicator
//

import Cocoa

public struct Symbolicator {
    let crashFile: CrashFile
    let dsymFiles: [DSYMFile]

    public var symbolicatedContent: String?
    public var errors = [String]()

    public init(crashFile: CrashFile, dsymFiles: [DSYMFile]) {
        self.crashFile = crashFile
        self.dsymFiles = dsymFiles
    }

    public mutating func symbolicate() -> Bool {
        errors.removeAll()

        guard let architecture = crashFile.architecture else {
            errors.append("Could not detect crash file architecture.")
            return false
        }

        guard !crashFile.binaryImages.isEmpty else {
            errors.append("""
            Could not detect application binary images from crash report. Application might have crashed during launch.
            """)
            return false
        }

        // There are some cases where the crash reports don't have any meaningful data to symbolicate,
        // Warn the user about them
        guard !crashFile.calls.isEmpty else {
            errors.append("""
            Did not find any stack trace calls to symbolicate.
            """)
            self.symbolicatedContent = crashFile.content
            return true
        }

        var callsByLoadAddress = [String: [StackTraceCall]]()
        crashFile.calls.forEach { call in
            callsByLoadAddress[call.loadAddress] = (callsByLoadAddress[call.loadAddress] ?? []) + [call]
        }

        var dsymsByLoadAddress = [String: DSYMFile]()
        crashFile.binaryImages.forEach { binaryImage in
            let dsymFile = dsymFiles.first {
                guard let uuidForArchitecture = $0.uuids[architecture] else { return false }
                return uuidForArchitecture == binaryImage.uuid
            }

            if let file = dsymFile {
                dsymsByLoadAddress[binaryImage.loadAddress] = file
            }
        }

        let replacedContent = NSMutableString(string: crashFile.content)
        var hasFailed = false

        callsByLoadAddress.forEach { loadAddress, calls in
            let addresses = calls.map { $0.address }

            guard let dsymFile = dsymsByLoadAddress[loadAddress] else { return }

            let command = symbolicationCommand(
                dsymPath: dsymFile.binaryPath,
                architecture: architecture.atosString!, // swiftlint:disable:this force_unwrapping
                loadAddress: loadAddress,
                addresses: addresses
            )

            let atosResult = command.run()
            let replacedSuccessfully = replaceContent(
                replacedContent,
                withAtosResult: atosResult,
                forAddresses: addresses,
                errors: &errors
            )

            if !replacedSuccessfully {
                hasFailed = true
            }
        }

        self.symbolicatedContent = replacedContent as String

        return !hasFailed
    }

    private func symbolicationCommand(
        dsymPath: String,
        architecture: String,
        loadAddress: String,
        addresses: [String]
    ) -> String {
        let addressesString = addresses.joined(separator: " ")
        return "xcrun atos -o \"\(dsymPath)\" -arch \(architecture) -l \(loadAddress) \(addressesString)"
    }

    private func replaceContent(
        _ content: NSMutableString,
        withAtosResult atosResult: CommandResult,
        forAddresses addresses: [String],
        errors: inout [String]
    ) -> Bool {
        if let error = atosResult.error?.trimmed, error != "" { errors.append(error) }

        if !errors.isEmpty {
            debugPrint(errors)
        }

        guard
            let output = atosResult.output?.trimmed,
            output.components(separatedBy: .newlines).count > 0
        else {
            errors.append("atos command gave no output")
            return false
        }

        let outputLines = output.components(separatedBy: .newlines)

        guard addresses.count == outputLines.count else {
            errors.append("Unexpected result from atos command:\n\(output)")
            return false
        }

        for index in 0..<outputLines.count {
            let address = addresses[index]
            let replacement = outputLines[index]

            // Replace the entries using the sample format
            let sampleReplacementRegex = try? NSRegularExpression(
                pattern: StackTraceCall.sampleReplacementRegex(address: address),
                options: [.caseInsensitive, .anchorsMatchLines]
            )
            sampleReplacementRegex?.replaceMatches(
                in: content,
                options: [],
                range: NSRange(location: 0, length: content.length),
                withTemplate: "\(replacement) [\(address)]"
            )

            // Replace the entries using the crash report format
            let crashReplacementRegex = try? NSRegularExpression(
                pattern: StackTraceCall.crashReplacementRegex(address: address),
                options: [.caseInsensitive, .anchorsMatchLines]
            )
            crashReplacementRegex?.replaceMatches(
                in: content,
                options: [],
                range: NSRange(location: 0, length: content.length),
                withTemplate: "\(address) \(replacement)"
            )
        }

        return true
    }
}
