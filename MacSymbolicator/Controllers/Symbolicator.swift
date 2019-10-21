//
//  Symbolicator.swift
//  MacSymbolicator
//

import Cocoa

public struct Symbolicator {
    let crashFile: CrashFile
    let dsymFile: DSYMFile

    public var symbolicatedContent: String?
    public var errors = [String]()

    static let architectures = [
        "X86-64": "x86_64",
        "X86": "i386",
        "PPC": "ppc"
    ]

    public init(crashFile: CrashFile, dsymFile: DSYMFile) {
        self.crashFile = crashFile
        self.dsymFile = dsymFile
    }

    public mutating func symbolicate() -> Bool {
        errors.removeAll()

        guard let architectureString = crashFile.architecture else {
            errors.append("Could not detect crash file architecture.")
            return false
        }

        let architecture = Symbolicator.architectures[architectureString] ?? architectureString

        guard let loadAddress = crashFile.loadAddress else {
            errors.append("""
            Could not detect application load address from crash report. Application might have crashed during launch.
            """)
            return false
        }

        // Fail silently as there are some cases where the crash reports don't have any meaningful data to symbolicate
        guard let addresses = crashFile.addresses, addresses.count > 0 else {
            self.symbolicatedContent = crashFile.content
            return true
        }

        let command = symbolicationCommand(
            dsymPath: dsymFile.binaryPath,
            architecture: architecture,
            loadAddress: loadAddress,
            addresses: addresses
        )

        let result = command.run()
        if let error = result.error?.trimmed, error != "" { errors.append(error) }

        if !errors.isEmpty {
            debugPrint(errors)
        }

        guard
            let output = result.output?.trimmed,
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

        var replacedContent = crashFile.content
        for index in 0..<outputLines.count {
            let address = addresses[index]
            let replacement = outputLines[index]

            // Replace the entries using the sample format
            let sampleOccurences = replacedContent.scan(pattern: "\\?{3}.*?\\[\(address)\\]").flatMap { $0 }
            sampleOccurences.forEach {
                replacedContent = replacedContent.replacingOccurrences(of: $0, with: "\(replacement) [\(address)]")
            }

            // Replace the entries using the crash report format
            let crashOccurences = replacedContent.scan(pattern: "\(address)\\s.*?$").flatMap { $0 }
            crashOccurences.forEach {
                replacedContent = replacedContent.replacingOccurrences(of: $0, with: "\(address) \(replacement)")
            }
        }

        self.symbolicatedContent = replacedContent

        return true
    }

    private func symbolicationCommand(
        dsymPath: String, architecture: String, loadAddress: String, addresses: [String]
    ) -> String {
        let addressesString = addresses.joined(separator: " ")
        return "xcrun atos -o \"\(dsymPath)\" -arch \(architecture) -l \(loadAddress) \(addressesString)"
    }
}
