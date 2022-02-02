//
//  MainWindowController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 Gergely Sánta. All rights reserved.
//

import Cocoa

extension NSToolbarItem.Identifier {
    static let customView = NSToolbarItem.Identifier("NSToolbarItemCustomView")
}

class MainWindowController: NSWindowController {

    let scanner = Scanner()
    var titlebarController: TitlebarController?

    private var exportProgressController: ExportProgressController?

    var mainViewController:MainViewController? {
        get {
            return MainViewController.instance
        }
    }

    var hasContent:Bool {
        get {
            return (mainViewController?.collectionView.numberOfSections ?? 0) > 0
        }
    }

    var isDragAndDropVisible:Bool {
        get {
            return mainViewController?.isDropViewVisible ?? false
        }
        set {
            mainViewController?.isDropViewVisible = newValue
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Set initial size of the window
        if let window = self.window {
            window.setFrame(NSRect(origin: window.frame.origin, size: CGSize(width: 1020, height: 700)), display: true)
        }

        scanner.delegate = self
        titlebarController = self.storyboard?.instantiateController(withIdentifier: "TitlebarController") as! TitlebarController?
        titlebarController?.delegate = self

        // Hide window title (text only, not the title bar)
        // This will also move the toolbar to titlebar automatically
        self.window?.titleVisibility = .hidden

        // Create main toolbar
        let mainToolbar = NSToolbar(identifier: "MainToolbar")
        mainToolbar.allowsUserCustomization = false
        mainToolbar.displayMode = .iconOnly
        mainToolbar.showsBaselineSeparator = true
        mainToolbar.delegate = self

        self.window?.toolbar = mainToolbar
    }

    func refreshPhotos() {
        // Reftesh collectionView
        mainViewController?.collectionView.reloadData()
        // Refresh window title
        titlebarController?.setTotalCount(AppData.shared.imageCollection.count)
    }

    func newExportProgressController() -> ExportProgressController? {
        exportProgressController = self.storyboard?.instantiateController(withIdentifier: "ExportProgressController") as? ExportProgressController
        return exportProgressController
    }

    func deleteExportProgressController() {
        exportProgressController = nil
    }

}

extension MainWindowController: NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let fileUrl = AppData.shared.openedFileUrl,
           AppData.shared.loadedImageSetChanged
        {
            appDelegate.confirmAction(NSLocalizedString("Your loaded scan changed. Do you want to save it before terminating application?", comment: "Confirmation for saving before termination"),
                                      forWindow: appDelegate.mainWindowController?.window,
                                      action: { (response) in
                                        if response {
                                            appDelegate.saveImageDatabase(fileUrl, onError: {})
                                            NSApp.terminate(self)
                                        }
            })
            return false
        }
        return true
    }

}

// MARK: - NSToolbarDelegate methods
extension MainWindowController: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ .customView ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ .customView ]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .customView {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = titlebarController?.view

            item.view?.translatesAutoresizingMaskIntoConstraints = false

            if let view = item.view {
                item.minSize = NSSize(width: 300, height: view.frame.size.height)
                item.maxSize = NSSize(width: 9999, height: view.frame.size.height)
            }

            return item
        }
        return nil
    }

}

// MARK: - TitlebarDelegate methods
extension MainWindowController: TitlebarDelegate {

    func titlebar(_ controller: TitlebarController, startScanForPath scanPath: String?) {
        let dialog = NSOpenPanel()
        let loadAccessoryController = self.storyboard?.instantiateController(withIdentifier: "LoadAccessoryController") as? LoadAccessoryController

        dialog.title = "Select a directory to scan"
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.allowsMultipleSelection = true
        dialog.accessoryView           = loadAccessoryController?.view
        dialog.isAccessoryViewDisclosed = true

        if let path = scanPath {
            dialog.directoryURL        = URL(fileURLWithPath: path)
        }

        let successBlock: (NSApplication.ModalResponse) -> Void = { response in
            if response == .OK {
                let directoryList = dialog.urls.map { $0.path }
                AppData.shared.setLookupDirectories(directoryList)

                // Create dummy reference of loadAccessoryController
                // This will create a strong reference to that controller from this block, so controller won't be
                // released until this block exists (until NSOpenPanel is not closed)
                _ = loadAccessoryController

                // Start scan without confirmation
                (NSApp.delegate as? AppDelegate)?.startScan(withConfirmation: false)
            }
        }

        if let window = self.window {
            dialog.beginSheetModal(for: window, completionHandler: successBlock)
        }
        else {
            dialog.begin(completionHandler: successBlock)
        }
    }

    func titlebar(_ controller: TitlebarController, cancelButtonPressed sender: NSButton) {
        self.scanner.stop()
    }

    func titlebarSidebarToggled(_ controller: TitlebarController) {
        MainSplitViewController.instance?.toggleSidebar(self)
    }

}

// MARK: - ScannerDelegate methods
extension MainWindowController: ScannerDelegate {

    func scanSubResult(scanner: Scanner) {
        #if DEBUG
        NSLog("Scan subresult: %d items", scanner.scannedCollection.count)
        #endif
        AppData.shared.imageCollection = scanner.scannedCollection

        refreshPhotos()
    }

    func scanFinished(scanner: Scanner) {
        #if DEBUG
        NSLog("Scan result: %d items", scanner.scannedCollection.count)
        #endif
        AppData.shared.imageCollection = scanner.scannedCollection

        refreshPhotos()

        titlebarController?.progressOn(false)
    }

}
