//
//  Symbolicator.swift
//  MacSymbolicator
//

import Cocoa

struct Symbolicator {
    let reportFile: ReportFile
    let dsymFiles: [DSYMFile]

    var symbolicatedContent: String?
    var logController: LogController

    init(reportFile: ReportFile, dsymFiles: [DSYMFile], logController: LogController) {
        self.reportFile = reportFile
        self.dsymFiles = dsymFiles
        self.logController = logController
    }

    mutating func symbolicate() async -> Bool {
        logController.resetLogs()

        var hasFailed = false

        await reportFile.processes.forEach { process in
            if symbolicateProcess(process) == false {
                hasFailed = true
            }
        }

        return !hasFailed
    }

    mutating func symbolicateProcess(_ process: ReportProcess) -> Bool {
        logController.addLogMessage("""
        —————————————————————————————————————————————————
        * Symbolicating process \(process.name ?? "<null>")
        """)

        guard let architecture = process.architecture else {
            logController.addLogMessage("Could not detect process architecture.")
            return false
        }

        // Some processes in spindump reports might not have anything besides the header;
        // Make sure to check that we have frames before dismissing it due to missing binary images section
        if !process.frames.isEmpty && process.binaryImages.isEmpty {
            logController.addLogMessage("""
            Could not detect application binary images for reported process \(process.name ?? "<null>").\
            Application might have crashed during launch.
            """)
            return false
        }

        // There are some cases where reports don't have any meaningful data to symbolicate,
        // Warn the user about them
        guard !process.frames.isEmpty else {
            logController.addLogMessage("""
            Did not find anything to symbolicate for process \(process.name ?? "<null>").
            """)
            return true
        }

        var framesByLoadAddress = [String: [StackFrame]]()
        process.frames.forEach { frame in
            if framesByLoadAddress[frame.binaryImage.loadAddress] == nil {
                framesByLoadAddress[frame.binaryImage.loadAddress] = []
            }

            framesByLoadAddress[frame.binaryImage.loadAddress]?.append(frame)
        }

        var dsymsByLoadAddress = [String: DSYMFile]()
        process.binaryImages.forEach { binaryImage in
            let dsymFile = dsymFiles.first {
                guard let uuidForArchitecture = $0.uuids[architecture] else { return false }
                return uuidForArchitecture == binaryImage.uuid
            }

            if let file = dsymFile {
                dsymsByLoadAddress[binaryImage.loadAddress] = file
            }
        }

        guard !dsymsByLoadAddress.isEmpty else {
            logController.addLogMessage("No dSYMs provided for symbolicating \(process.name ?? "<null>")")
            return true
        }

        let replacedContent = NSMutableString(string: symbolicatedContent ?? reportFile.content)
        var hasFailed = false

        framesByLoadAddress.forEach { loadAddress, frames in
            let addresses = frames.map { $0.address }

            guard let dsymFile = dsymsByLoadAddress[loadAddress] else { return }

            let command = symbolicationCommand(
                dsymPath: dsymFile.binaryPath,
                architecture: architecture.atosString!, // swiftlint:disable:this force_unwrapping
                loadAddress: loadAddress,
                addresses: addresses
            )
            logController.addLogMessage("Running command: \(command)")

            let atosResult = command.run()

            logController.addLogMessages([
                "STDOUT:\n\(atosResult.output?.trimmed ?? "")",
                "STDERR:\n\(atosResult.error?.trimmed ?? "")"
            ])

            var errors = [String]()
            let replacedSuccessfully = replaceContent(
                replacedContent,
                withAtosResult: atosResult,
                for: frames,
                errors: &errors
            )
            logController.addLogMessages(errors)

            if !replacedSuccessfully {
                logController.addLogMessage("Couldn't replace report entries with atos result")
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
        for frames: [StackFrame],
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

        guard frames.count == outputLines.count else {
            errors.append("Unexpected result from atos command:\n\(output)")
            return false
        }

        for index in 0..<outputLines.count {
            let frame = frames[index]
            let replacement = outputLines[index]

            frame.replace(withResult: replacement)

            if let symbolicatedLine = frame.symbolicatedLine {
                logController.addLogMessage(
                    "Replacing matches in sample/spindump report: \(String(describing: frame.line))"
                )

                content.replaceOccurrences(
                    of: frame.line,
                    with: symbolicatedLine,
                    range: NSRange(location: 0, length: content.length)
                )
            }
        }

        return true
    }
}
