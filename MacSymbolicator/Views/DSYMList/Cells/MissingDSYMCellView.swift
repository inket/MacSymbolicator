//
//  MissingDSYMCellView.swift
//  MacSymbolicator
//

import Cocoa

final class MissingDSYMCellView: DSYMCellView {
    let dsymRequirement: DSYMRequirement

    private let text: String
    private let uuids: String

    init(dsymRequirement: DSYMRequirement) {
        self.dsymRequirement = dsymRequirement

        let targetLabel = NSTextField(labelWithString: dsymRequirement.targetName)
        targetLabel.textColor = NSColor.secondaryLabelColor
        targetLabel.font = NSFont.controlContentFont(ofSize: NSFont.systemFontSize)

        let uuidLabel = NSTextField(labelWithString: dsymRequirement.uuid.pretty)
        uuidLabel.textColor = NSColor.secondaryLabelColor
        uuidLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        uuidLabel.toolTip = dsymRequirement.uuid.pretty

        uuids = dsymRequirement.uuid.pretty
        text = [dsymRequirement.targetName, uuids].joined(separator: "\n")

        super.init(frame: .zero)

        for view in [targetLabel, uuidLabel] {
            stackView.addArrangedSubview(view)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MissingDSYMCellView: InteractableDSYMCellView {
    func representedFileURL() -> URL? {
        nil
    }

    func copyableText() -> String {
        text
    }

    func copyableUUIDs() -> String {
        uuids
    }
}
