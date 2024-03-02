//
//  main.swift
//  MacSymbolicatorCLI
//

import Foundation
import ArgumentParser

@main
struct MacSymbolicatorCLI: ParsableCommand {
    enum SymbolicationError: Error {
        case undefined
    }

    @Flag(name: .shortAndLong, help: "Translate the crash report from .ips to .crash")
    var translateOnly = false

    @Flag(name: .shortAndLong, help: "Output binary images and UUIDs")
    var uuidsOnly = false

    @Flag(name: .shortAndLong)
    var verbose = false

    @Option(name: .shortAndLong, help: "The output file to save the result to, instead of printing to stdout")
    var output: String?

    @Argument(help: "The report file: .crash/.ips for crash reports .txt for samples/spindumps")
    var reportFilePath: String

    @Argument(help: "The dSYMs to use for symbolication")
    var dsymPath: [String] = []

    mutating func run() throws {
        if !translateOnly, !uuidsOnly, dsymPath.isEmpty {
            MacSymbolicatorCLI.exit(
                withError: ArgumentParser.ValidationError.init("Missing expected argument '<dsym-path>'")
            )
        }

        let reportFile = try ReportFile(path: URL(fileURLWithPath: reportFilePath))

        if translateOnly {
            try translateReport(reportFile)
        }

        if uuidsOnly {
            try printUUIDsForReport(reportFile)
        }

        let dsymFiles: [DSYMFile] = dsymPath.compactMap { path in
            let file = DSYMFile(path: URL(fileURLWithPath: path))
            if file == nil, verbose {
                print("Could not load dsym file: \(path)")
            }
            return file
        }

        if verbose {
            print("---------")
            print("Symbolicating with:")

            let reportUUIDs = reportFile.uuidsForSymbolication.map { $0.pretty }.joined(separator: ", ")
            print("Report: \(reportFile.path.path) [\(reportUUIDs)]")

            let dsymDescriptions: [String] = dsymFiles.map {
                let uuids = $0.uuids.map { "    \($0.key): \($0.value.pretty)" }

                return "DSYM file: \($0.binaryPath)\n\(uuids.joined(separator: "\n"))"
            }
            print(dsymDescriptions.joined(separator: "\n"))
            print("---------")
        }

        var symbolicator = Symbolicator(
            reportFile: reportFile,
            dsymFiles: dsymFiles,
            logController: DefaultLogController()
        )

        let success = symbolicator.symbolicate()

        if success {
            if verbose {
                print(symbolicator.logController.logMessages.joined(separator: "\n"))
            }

            if verbose, output == nil {
                print("---------")
                print("Output:")
            }

            if let output = output, let symbolicatedContent = symbolicator.symbolicatedContent {
                try symbolicatedContent.write(toFile: output, atomically: false, encoding: .utf8)
            } else {
                let fallbackOutput = verbose ? "No symbolicated content" : ""
                print(symbolicator.symbolicatedContent ?? fallbackOutput)
            }
        } else {
            print("Symbolication failed.")
            print(symbolicator.logController.logMessages.joined(separator: "\n"))
            MacSymbolicatorCLI.exit(withError: SymbolicationError.undefined)
        }
    }

    private func translateReport(_ reportFile: ReportFile) throws {
        if let output = output {
            try reportFile.content.write(toFile: output, atomically: false, encoding: .utf8)
        } else {
            print(reportFile.content)
        }

        MacSymbolicatorCLI.exit(withError: nil)
    }

    private func printUUIDsForReport(_ reportFile: ReportFile) throws {
        let dsymIdents = reportFile.processes.map {
            $0.binariesForSymbolication.map { "\($0.name)/\($0.uuid.pretty)"}.joined(separator: "\n")
        }.joined(separator: "\n")

        if let output = output {
            try dsymIdents.write(toFile: output, atomically: false, encoding: .utf8)
        } else {
            print(dsymIdents)
        }

        MacSymbolicatorCLI.exit(withError: nil)
    }
}
