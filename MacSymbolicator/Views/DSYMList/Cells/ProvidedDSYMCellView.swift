//
//  ProvidedDSYMCellView.swift
//  MacSymbolicator
//

import Cocoa

final class ProvidedDSYMCellView: DSYMCellView {
    let providedDSYM: DSYMListViewModel.ProvidedDSYM

    private let text: String
    private let uuids: String

    init(providedDSYM: DSYMListViewModel.ProvidedDSYM) {
        self.providedDSYM = providedDSYM

        let filename = providedDSYM.path.lastPathComponent

        let filenameLabel = NSTextField(labelWithString: filename)
        filenameLabel.font = NSFont.controlContentFont(ofSize: NSFont.systemFontSize)

        var uuids = [String]()
        let uuidLabels = providedDSYM.uuids.map {
            let stringComponents = [$0.architecture?.atosString, $0.pretty].compactMap { $0 }
            let value = stringComponents.joined(separator: ": ")

            uuids.append(value)

            let uuidLabel = NSTextField(labelWithString: value)
            uuidLabel.textColor = NSColor.secondaryLabelColor
            uuidLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            return uuidLabel
        }

        let uuidsStackView = NSStackView(views: uuidLabels)
        uuidsStackView.orientation = .vertical
        uuidsStackView.distribution = .equalCentering
        uuidsStackView.alignment = .leading
        uuidsStackView.spacing = 0
        uuidsStackView.translatesAutoresizingMaskIntoConstraints = false

        let containingPath = (providedDSYM.path.deletingLastPathComponent().path as NSString)
            .abbreviatingWithTildeInPath
        let pathLabel = NSTextField(labelWithString: containingPath)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.font = NSFont.controlContentFont(ofSize: NSFont.labelFontSize)
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.toolTip = containingPath
        pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.uuids = uuids.joined(separator: "\n")
        text = [filename, self.uuids, containingPath].joined(separator: "\n")

        super.init(frame: .zero)

        for view in [filenameLabel, uuidsStackView, pathLabel] {
            stackView.addArrangedSubview(view)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProvidedDSYMCellView: InteractableDSYMCellView {
    func representedFileURL() -> URL? {
        providedDSYM.path
    }

    func copyableText() -> String {
        text
    }

    func copyableUUIDs() -> String {
        uuids
    }
}
