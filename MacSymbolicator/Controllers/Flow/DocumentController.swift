//
//  DocumentController.swift
//  MacSymbolicator
//

import Cocoa
import Combine

final class SymbolicatorSplitViewController: NSSplitViewController {
//    private class SymbolicatorSplitView: NSSplitView {
//        holdin
//    }
//
//    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        commonInit()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        commonInit()
//    }
//
//    private func commonInit() {
//        splitView = SymbolicatorSplitView()
//    }
}

@MainActor
protocol DocumentControllerDelegate: AnyObject {
    func documentControllerWillClose(_ documentController: DocumentController)
}

@MainActor
final class DocumentController: NSObject {
    private enum Layout {
        static let initialContentSize = CGSize(width: 500, height: 300)
        static let symbolicatingContentSize = CGSize(width: 1460, height: 860)
        static let symbolicatingMinimumContentSize = CGSize(width: 800, height: 400)
        static let initialSidebarWidth: CGFloat = 340
    }

    private let window = NSWindow()

    private let logController: any LogController

    private let viewModel: DocumentViewModel

    private weak var delegate: (any DocumentControllerDelegate)?

    private var cancellables = Set<AnyCancellable>()

    private let skipsAnimation: Bool = false

    private let reportFileViewController: ReportFileViewController

    // MARK: - Properties for the symbolicating state

    private let splitViewController = SymbolicatorSplitViewController()
    private var symbolicatorViewController: SymbolicatorViewController?
    private var dsymFilesOnHold: [DSYMFile] = []
    private var dsymListViewController: DSYMListViewController?

    // MARK: - Methods

    init(reportFile: ReportFile?, index: Int, delegate: any DocumentControllerDelegate) {
        logController = DefaultLogController()
        viewModel = DocumentViewModel(reportFile: reportFile)
        reportFileViewController = ReportFileViewController(reportFile: reportFile, logController: logController)
        self.delegate = delegate

        super.init()

        reportFileViewController.delegate = self

        window.isReleasedWhenClosed = false
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        window.titleVisibility = .visible
        window.title = "MacSymbolicator"
        window.setContentSize(Layout.initialContentSize)
        window.contentMinSize = Layout.initialContentSize
        window.contentMaxSize = Layout.initialContentSize
        window.center()
        window.setFrameOrigin(
            CGPoint(
                x: window.frame.origin.x + CGFloat(index) * 40,
                y: window.frame.origin.y + CGFloat(index) * 40
            )
        )
        window.delegate = self

        let contentView = window.contentView!
        contentView.addSubview(reportFileViewController.view)
        reportFileViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reportFileViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            reportFileViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            reportFileViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            reportFileViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        window.makeKeyAndOrderFront(nil)

        viewModel.state.sink { [weak self] newState in
            Task {
                await self?.update(from: newState)
            }
        }.store(in: &cancellables)
    }

    @MainActor
    private func update(from state: DocumentViewModel.State) async {
        switch state {
        case .initial(let reportFile):
            window.subtitle = reportFile?.filename ?? ""
        case .symbolicating(let reportFile):
            let symbolicatorViewModel = SymbolicatorViewModel(reportFile: reportFile, defaultSaveURL: nil)
            let symbolicatorViewController = SymbolicatorViewController(viewModel: symbolicatorViewModel)

            let dsymListViewController = DSYMListViewController(
                reportFile: reportFile,
                dsymRequirements: await reportFile.dsymRequirements,
                logController: logController
            )
            dsymListViewController.minimumWidth = Layout.initialSidebarWidth
            _ = dsymListViewController.acceptDSYMFiles(dsymFilesOnHold)
            self.dsymListViewController = dsymListViewController

            let dsymListSplitViewItem = NSSplitViewItem(sidebarWithViewController: dsymListViewController)
            dsymListSplitViewItem.canCollapse = false
            dsymListSplitViewItem.minimumThickness = Layout.initialSidebarWidth
            let textViewSplitViewItem = NSSplitViewItem(contentListWithViewController: symbolicatorViewController)
            textViewSplitViewItem.minimumThickness = 500
            splitViewController.addSplitViewItem(dsymListSplitViewItem)
            splitViewController.addSplitViewItem(textViewSplitViewItem)

            splitViewController.view.alphaValue = 0
            splitViewController.view.translatesAutoresizingMaskIntoConstraints = false

            window.contentViewController = splitViewController

            if skipsAnimation {
                reportFileViewController.view.removeFromSuperview()
                window.resizeToFit(contentSize: Layout.symbolicatingContentSize, animated: false)
                splitViewController.view.alphaValue = 1
                self.window.setContentSize(Layout.symbolicatingContentSize)
                self.window.contentMinSize = Layout.symbolicatingMinimumContentSize
                self.window.contentMaxSize = CGSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )
                dsymListViewController.appearAnimationCompleted()
            } else {
                NSAnimationContext.runAnimationGroup(
                    { context in
                        context.duration = 0.2
                        context.allowsImplicitAnimation = true
                        self.reportFileViewController.view.animator().alphaValue = 0
                    },
                    completionHandler: {
                        self.reportFileViewController.view.removeFromSuperview()
                    }
                )

                NSAnimationContext.runAnimationGroup(
                    { context in
                        context.duration = 0.4
                        context.allowsImplicitAnimation = true

                        self.window.resizeToFit(contentSize: Layout.symbolicatingContentSize, animated: false)
                        self.splitViewController.view.animator().alphaValue = 1
                    },
                    completionHandler: {
                        self.window.setContentSize(Layout.symbolicatingContentSize)
                        self.window.contentMinSize = Layout.symbolicatingMinimumContentSize
                        self.window.contentMaxSize = CGSize(
                            width: CGFloat.greatestFiniteMagnitude,
                            height: CGFloat.greatestFiniteMagnitude
                        )

                        DispatchQueue.main.async {
                            dsymListViewController.appearAnimationCompleted()
                        }
                    }
                )
            }

            window.subtitle = reportFile.filename
        }
    }

    func acceptReportFile(_ reportFile: ReportFile) -> ReportFileViewModel.ReportFileOpenReply {
        reportFileViewController.acceptReportFile(reportFile)
    }

    func acceptDSYMFiles(_ dsymFiles: [DSYMFile]) -> Bool {
        switch viewModel.state.value {
        case .initial:
            dsymFilesOnHold.append(contentsOf: dsymFiles)
            return true
        case .symbolicating:
            return dsymListViewController?.acceptDSYMFiles(dsymFiles) ?? false
        }
    }

    func orderFront() {
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - ReportFileViewControllerDelegate

extension DocumentController: ReportFileViewControllerDelegate {
    func reportFileViewController(
        _ reportFileViewController: ReportFileViewController,
        acquiredReportFile reportFile: ReportFile
    ) {
        viewModel.acquiredReportFile(reportFile)
    }
}

// MARK: - NSWindowDelegate

extension DocumentController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        delegate?.documentControllerWillClose(self)
    }
}
