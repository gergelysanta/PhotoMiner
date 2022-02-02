//
//  AppDelegate.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 Gergely Sánta. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Instance properties

    var mainWindowController:MainWindowController? {
        get {
            for window in NSApp.windows {
                if let controller = window.windowController as? MainWindowController {
                    return controller
                }
            }
            return nil
        }
    }

    @objc dynamic var isListingAvailable:Bool {
        get {
            let imagesAvailable = AppData.shared.imageCollection.count > 0
            if let scanning = mainWindowController?.scanner.isRunning {
                // Listing is available only when not scanning
                return scanning ? false : imagesAvailable
            }
            return imagesAvailable
        }
    }

    // MARK: - NSApplicationDelegate methods

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.directoryListNeedingAccessChanged(notification:)), name: AppData.listOfFoldersRequiringAccessChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.displayAlertDialog(notification:)), name: AppData.displayAlertDialog, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if filename.hasSuffix(".\(Configuration.shared.saveDataExtension)") {
            return loadImageDatabase(URL(fileURLWithPath: filename))
        }
        else if AppData.shared.setLookupDirectories([filename]),
                let appDelegate = NSApp.delegate as? AppDelegate
        {
            appDelegate.startScan(withConfirmation: true)
            return true
        }
        return false
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let savedDataFiles = filenames.filter { $0.hasSuffix(".\(Configuration.shared.saveDataExtension)") }
        if savedDataFiles.count > 0 {
            for filename in savedDataFiles {
                if loadImageDatabase(URL(fileURLWithPath: filename)) {
                    return
                }
            }
        }
        else if AppData.shared.setLookupDirectories(filenames) {
            startScan(withConfirmation: true)
        }
    }

    @objc func directoryListNeedingAccessChanged(notification: Notification) {
        if AppData.shared.accessNeededForFolders.count > 1 {
            mainWindowController?.mainViewController?.dropViewText = String.localizedStringWithFormat(NSLocalizedString("To give access to files in opened scan you need to start a scan for the following directories or drop them here:\n%@", comment: "Action needed for accessing more directories: drop view description"), AppData.shared.accessNeededForFolders.joined(separator: "\n"))
        }
        else if AppData.shared.accessNeededForFolders.count > 0 {
            mainWindowController?.mainViewController?.dropViewText = String.localizedStringWithFormat(NSLocalizedString("To give access to files in opened scan you need to start a scan for the following directory or drop it here:\n%@", comment: "Action needed for accessing one directory: drop view description"), AppData.shared.accessNeededForFolders.joined(separator: "\n"))
        }
        else {
            mainWindowController?.mainViewController?.dropViewText = nil
        }
    }

    @objc func displayAlertDialog(notification: Notification) {
        guard let window = mainWindowController?.window else { return }
        if let error = notification.userInfo?["error"] as? String {
            self.displaySheet(withMessage: error, ofType: .critical, forWindow: window)
        } else if let warning = notification.userInfo?["warning"] as? String {
            self.displaySheet(withMessage: warning, ofType: .warning, forWindow: window)
        } else if let notification = notification.userInfo?["notification"] as? String{
            self.displaySheet(withMessage: notification, ofType: .informational, forWindow: window)
        }
    }

    // MARK: - Scan

    private func internalStartScan() {
        // We're starting a new scan, clean parsed data (won't be displayed)
        AppData.shared.parsedImageCollection = nil

        let scanStarted = mainWindowController?.scanner.start(pathsToScan: AppData.shared.lookupFolders,
                                                              bottomSizeLimit: Configuration.shared.ignoreImagesBelowSize) ?? false
        if scanStarted {
            AppData.shared.openedFileUrl = nil
            AppData.shared.addGrantedDirectories(AppData.shared.lookupFolders)
        }
        else {
            // TODO: Display Warning
        }
        mainWindowController?.titlebarController?.progressOn(true)
    }

    private func internalCheckParsedScan() {
        // Check if we have cached scan (loaded from pms file)
        if let cachedCollection = AppData.shared.parsedImageCollection {
            var directoryNotFromLoadedScanDropped = false

            // We're starting a new scan (by opening dir or drag&drop)
            // but we have a pms file loaded, we need allowing access to those files first

            // Check if these directories are part of our loaded scan
            // If yes, remove them form "need access" set (access granted by starting scan session)
            // If not, ask user if he really wants to start a new scan (will cancel loaded scan)
            for path in AppData.shared.lookupFolders {
                if !AppData.shared.grantAccessForCachedFolder(path) {
                    // Requested directory is NOT part of the loaded scan
                    directoryNotFromLoadedScanDropped = true
                }
            }
            if directoryNotFromLoadedScanDropped {
                let scanCompletionHandler: (Bool) -> Void = { response in
                    if response {
                        AppData.shared.cleanCachedFolders()
                        self.internalStartScan()
                    }
                }
                self.confirmAction(NSLocalizedString("Are you sure you want to start a new scan?", comment: "Confirmation for starting new scan"),
                                   details: NSLocalizedString("You requested to scan a directory which is not part of the loaded scan.", comment: "You requested to scan a directory which is not part of the loaded scan."),
                                   forWindow: mainWindowController?.window,
                                   action: scanCompletionHandler)
                return
            }
            else {
                if AppData.shared.accessNeededForFolders.isEmpty {
                    // A scan file was parsed and all the directories are allowed by system, we can display the data
                    AppData.shared.imageCollection = cachedCollection
                    mainWindowController?.refreshPhotos()
                    mainWindowController?.titlebarController?.progressOn(false)
                    AppData.shared.parsedImageCollection = nil
                    AppData.shared.setLookupDirectories(cachedCollection.rootDirs)
                    AppData.shared.addGrantedDirectories(AppData.shared.lookupFolders)
                }
                return
            }
        }
        internalStartScan()
    }

    func startScan(withConfirmation: Bool) {
        if let windowController = mainWindowController,
                AppData.shared.parsedImageCollection == nil,
                withConfirmation && Configuration.shared.newScanMustBeConfirmed && windowController.hasContent
        {
            self.confirmAction(NSLocalizedString("Are you sure you want to start a new scan?", comment: "Confirmation for starting new scan"),
                               forWindow: windowController.window)
            { (response: Bool) in
                if response {
                    self.internalStartScan()
                } else {
                    windowController.isDragAndDropVisible = false
                }
            }
        }
        else {
            internalCheckParsedScan()
        }
    }

    // MARK: - Instance methods

    func displaySheet(withMessage message: String, andInformativeText infoText: String?, ofType type: NSAlert.Style, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = infoText ?? ""
        alert.alertStyle = type
        alert.addButton(withTitle: "OK")
        alert.buttons[0].keyEquivalent = "\r"
        alert.beginSheetModal(for: window) { (result) in
            completionHandler?()
        }
    }

    func displaySheet(withMessage message: String, ofType type: NSAlert.Style, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
        displaySheet(withMessage: message, andInformativeText: nil, ofType: type, forWindow: window, completionHandler: completionHandler)
    }

    func confirmAction(_ question: String, details: String, forWindow window: NSWindow?, action: ((Bool) -> Void)? = nil) {
        let popup = NSAlert()
        popup.messageText = question
        popup.informativeText = details
        popup.alertStyle = .warning
        popup.addButton(withTitle: NSLocalizedString("No", comment: "No"))
        popup.addButton(withTitle: NSLocalizedString("Yes", comment: "Yes"))
        popup.buttons[0].keyEquivalent = ""
        popup.buttons[1].keyEquivalent = "\r"
        if let window = window {
            popup.beginSheetModal(for: window) { (response) in
                action?((response == NSApplication.ModalResponse.alertSecondButtonReturn) ? true : false)
            }
        }
        else {
            let response = popup.runModal()
            action?((response == NSApplication.ModalResponse.alertSecondButtonReturn) ? true : false)
        }
    }

    func confirmAction(_ question: String, forWindow window: NSWindow?, action: @escaping ((Bool) -> Swift.Void)) {
        confirmAction(question, details: "", forWindow: window, action: action)
    }

    @discardableResult func loadImageDatabase(_ fileUrl: URL, onError errorHandler: (() -> Void)? = nil) -> Bool {
        do {
            // Parse scan database from file
            let parsedCollection = try JSONDecoder().decode(ImageCollection.self, from: Data(contentsOf: fileUrl))

            // Collect directories of this scan which weren't allowed by user yet
            AppData.shared.cleanCachedFolders()

            // Remember opene file URL
            AppData.shared.openedFileUrl = fileUrl

            for path in parsedCollection.rootDirs {
                if !AppData.shared.wasDirectoryGranted(path) {
                    AppData.shared.cacheFolderForRequestingAccess(path)
                }
            }
            if AppData.shared.accessNeededForFolders.count > 0 {
                // Parsed scan contains at least one not yet allowed directory
                // Display information...
                if let window = mainWindowController?.window,
                   Configuration.shared.displayWarningForParsedScans
                {
                    self.displaySheet(withMessage: NSLocalizedString("Action needed for accessing directories", comment: "Action needed for accessing directories"),
                                      andInformativeText: NSLocalizedString("System do not allows to read directories which weren't opened through OpenDialog or Drag&Drop. Because of this we open Finder for you with pre-selected directories each time you load a saved scan with directories which weren't accepted by user yet. You need to Drag&Drop these directories to the application's window in order to give access.", comment: "Action needed for accessing directories: dialog info"),
                                      ofType: .critical,
                                      forWindow: window) {
                                            self.mainWindowController?.isDragAndDropVisible = false
                                      }
                    Configuration.shared.displayWarningForParsedScans = false
                }
                else {
                    mainWindowController?.isDragAndDropVisible = false
                }

                // ...and open Finder with preselected directory
                for path in AppData.shared.accessNeededForFolders {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                }
                // Remember this parse
                AppData.shared.parsedImageCollection = parsedCollection
                // That's all for parsed scan for now
                return true
            }

            // All directories in this scan were allowed previously by user
            // no additional steps needed, just read scan and display it :)
            AppData.shared.imageCollection = parsedCollection

            self.mainWindowController?.refreshPhotos()
            return true
        } catch {
            errorHandler?()
            if let window = mainWindowController?.window {
                self.displaySheet(withMessage: String.localizedStringWithFormat(NSLocalizedString("Couldn't parse scan from %@", comment: "Couldn't parse scan from file"), fileUrl.path),
                                  andInformativeText: NSLocalizedString("File is corrupted or it's not a scan result", comment: "File is corrupted or it's not a scan result"),
                                  ofType: .critical,
                                  forWindow: window) {
                                        self.mainWindowController?.refreshPhotos()
                                  }
            }
        }
        return false
    }

    @discardableResult func saveImageDatabase(_ fileUrl: URL, onError errorHandler: () -> Void) -> Bool {
        if let jsonData = try? JSONEncoder().encode(AppData.shared.imageCollection) {
            do {
                try jsonData.write(to: fileUrl)
                AppData.shared.loadedImageSetChanged = false
                return true
            } catch {
                errorHandler()
                if let window = mainWindowController?.window {
                    displaySheet(withMessage: String.localizedStringWithFormat(NSLocalizedString("Couldn't save scan to %@", comment: "Couldn't save scan to file"), fileUrl.path),
                                 ofType: .critical,
                                 forWindow: window)
                }
            }
        }
        else {
            errorHandler()
            if let window = mainWindowController?.window {
                displaySheet(withMessage: NSLocalizedString("Couldn't prepare data for saving", comment: "Couldn't prepare data for saving"),
                             ofType: .critical,
                             forWindow: window)
            }
        }
        return false
    }

    // MARK: - Actions

    @IBAction func prefsMenuItemPressed(_ sender: NSMenuItem) {
        if let titleBarController = self.mainWindowController?.titlebarController {
            titleBarController.showSettings()
        }
    }

    @IBAction func openMenuItemPressed(_ sender: NSMenuItem) {
        guard let window = mainWindowController?.window else { return }

        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = [ Configuration.shared.saveDataExtension ]

        openPanel.beginSheetModal(for: window) { (response:NSApplication.ModalResponse) in
            if response == .OK {
                if let fileUrl = openPanel.url {
                    self.loadImageDatabase(fileUrl, onError: {
                        openPanel.close()
                    })
                }
            }
        }
    }

    @IBAction func saveMenuItemPressed(_ sender: NSMenuItem) {
        if let fileUrl = AppData.shared.openedFileUrl {
            saveImageDatabase(fileUrl, onError: {})
        }
        else {
            saveAsMenuItemPressed(sender)
        }
    }

    @IBAction func saveAsMenuItemPressed(_ sender: NSMenuItem) {
        guard let window = mainWindowController?.window else { return }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = [ Configuration.shared.saveDataExtension ]

        savePanel.beginSheetModal(for: window, completionHandler: { (response:NSApplication.ModalResponse) in
            if response == .OK {
                if let fileUrl = savePanel.url {
                    if self.saveImageDatabase(fileUrl, onError: { savePanel.close() }) {
                        AppData.shared.openedFileUrl = fileUrl
                    }
                }
            }
        })
    }

    @IBAction func exportScannedPhotosMenuItemPressed(_ sender: NSMenuItem) {
        guard
            let window = mainWindowController?.window,
            let storyboard = mainWindowController?.storyboard,
            let exportAccessoryController = storyboard.instantiateController(withIdentifier: "ExportAccessoryController") as? ExportAccessoryController,
            let exportProgressController = storyboard.instantiateController(withIdentifier: "ExportProgressController") as? ExportProgressController
        else { return }

        // Create export sheet (open panel for selecting destination directory)
        let dialog = NSOpenPanel()
        dialog.title = "Select a destination for exporting your photos"
        dialog.showsHiddenFiles         = false
        dialog.canCreateDirectories     = true
        dialog.canChooseDirectories     = true
        dialog.canChooseFiles           = false
        dialog.allowsMultipleSelection  = false
        dialog.accessoryView            = exportAccessoryController.view
        dialog.isAccessoryViewDisclosed = true

        // Rename "Open" button
        dialog.prompt = NSLocalizedString("Export", comment: "Export button")

        // Block called periodically from export
        let exportReportingProgress = { (sourcePath: String, destinationPath: String, percentComplete: Double) in
            exportProgressController.progressBar.doubleValue = percentComplete
        }

        // Display export sheet
        dialog.beginSheetModal(for: window) { (response: NSApplication.ModalResponse) in
            if response == .OK {
                guard let fileUrl = dialog.url else { return }

                let removeOldFiles = exportAccessoryController.removeAfterExporting

                // Close export sheet
                dialog.close()

                // Shade content
                self.mainWindowController?.mainViewController?.shadeView.show()

                // Open sheet displaying progress
                let exportDialog = NSWindow()
                exportDialog.contentView = exportProgressController.view
                exportProgressController.progressBar.doubleValue = 0
                window.beginSheet(exportDialog) { (response: NSApplication.ModalResponse) in
                    // Close dialog if 'Cancel' pressed
                    if response == .cancel {
                        // Closed
                        AppData.shared.imageCollection.exportStop()
                    }
                    // Unshade content
                    self.mainWindowController?.mainViewController?.shadeView.hide()
                }

                AppData.shared.imageCollection.exportStart(toDirectory: fileUrl,
                                                           removeOriginals: removeOldFiles,
                                                           reportProgress: exportReportingProgress)
                {
                    // Scan ended, close the progress sheet (check first whether it was already closed)
                    if exportDialog.sheetParent == window {
                        window.endSheet(exportDialog, returnCode: .OK)
                    }
                    self.mainWindowController?.mainViewController?.collectionView.reloadData()
                }
            }
        }
    }

    @IBAction func sendFeedbackMenuItemPressed(_ sender: NSMenuItem) {
        // Send an email
        if let emailService = NSSharingService(named: NSSharingService.Name.composeEmail) {
            emailService.subject = NSLocalizedString("Feedback for PhotoMiner", comment: "Feedback for PhotoMiner")
            emailService.recipients = ["gergely.santa@icloud.com"]
            emailService.perform(withItems: [])
        }
    }

}
