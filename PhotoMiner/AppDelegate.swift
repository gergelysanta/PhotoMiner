//
//  AppDelegate.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	// MARK: - Instance properties
	
	var imageCollection = ImageCollection(withDirectories: [])
	
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
	
	private var parsedImageCollection:ImageCollection?
	private var notYetAllowedParsedDirs = [String]() {
		didSet {
			if notYetAllowedParsedDirs.count > 1 {
				mainWindowController?.mainViewController?.dropViewText = String.localizedStringWithFormat(NSLocalizedString("To give access to files in opened scan you need to start a scan for the following directories or drop them here:\n%@", comment: "Action needed for accessing more directories: drop view description"), notYetAllowedParsedDirs.joined(separator: "\n"))
			}
			else if notYetAllowedParsedDirs.count > 0 {
				mainWindowController?.mainViewController?.dropViewText = String.localizedStringWithFormat(NSLocalizedString("To give access to files in opened scan you need to start a scan for the following directory or drop it here:\n%@", comment: "Action needed for accessing one directory: drop view description"), notYetAllowedParsedDirs.joined(separator: "\n"))
			}
			else {
				mainWindowController?.mainViewController?.dropViewText = nil
			}
		}
	}

	@objc dynamic var isListingAvailable:Bool {
		get {
			let imagesAvailable = self.imageCollection.count > 0
			if let scanning = mainWindowController?.scanner.isRunning {
				// Listing is available only when not scanning
				return scanning ? false : imagesAvailable
			}
			return imagesAvailable
		}
	}
	
	// MARK: - NSApplicationDelegate methods
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		if let fileUrl = Configuration.shared.openedFileUrl,
			Configuration.shared.openedFileChanged
		{
			self.confirmAction(NSLocalizedString("Your loaded scan changed. Do you want to save it before terminating application?", comment: "Confirmation for saving before termination"),
							   forWindow: mainWindowController?.window,
							   action: { (response) in
								if response {
									self.saveImageDatabase(fileUrl, onError: {})
								}
								NSApp.terminate(self)
							})
			return .terminateLater
		}
		return .terminateNow
	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		if filename.hasSuffix(".\(Configuration.shared.saveDataExtension)") {
			return loadImageDatabase(URL(fileURLWithPath: filename))
		}
		else if Configuration.shared.setLookupDirectories([filename]),
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
		else if Configuration.shared.setLookupDirectories(filenames) {
			startScan(withConfirmation: true)
		}
	}
	
	// MARK: - Scan
	
	private func internalStartScan() {
		parsedImageCollection = nil
		
		let scanStarted = mainWindowController?.scanner.start(pathsToScan: Configuration.shared.lookupFolders,
															  bottomSizeLimit: Configuration.shared.ignoreImagesBelowSize) ?? false
		if scanStarted {
			Configuration.shared.openedFileUrl = nil
			Configuration.shared.addScannedDirectories(Configuration.shared.lookupFolders)
		}
		else {
			// TODO: Display Warning
		}
		mainWindowController?.titlebarController?.progressOn(true)
	}
	
	private func internalCheckParsedScan() {
		// Check if we have cached scan (loaded from pms file)
		if let cachedCollection = parsedImageCollection {
			var alienDirectoryDetected = false
			// We have a pms file loaded, we need allowing access to those files first
			if !notYetAllowedParsedDirs.isEmpty {
				// A scan file was parsed but not all directories were accepted yet
				for path in Configuration.shared.lookupFolders {
					if let pathindex = notYetAllowedParsedDirs.index(of: path) {
						// Requested directory is part of the loaded scan
						// User granted access to it, we can remove from the array of needed directories
						notYetAllowedParsedDirs.remove(at: pathindex)
					}
					else {
						// Requested directory is not part of the loaded scan
						alienDirectoryDetected = true
					}
				}
			}
			if alienDirectoryDetected {
				let scanCompletionHandler: (Bool) -> Void = { response in
					if response {
						self.notYetAllowedParsedDirs = []
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
				if notYetAllowedParsedDirs.isEmpty {
					// A scan file was parsed and all the directories are allowed by system, we can display the data
					self.imageCollection = cachedCollection
					mainWindowController?.refreshPhotos()
					mainWindowController?.titlebarController?.progressOn(false)
					parsedImageCollection = nil
					Configuration.shared.setLookupDirectories(cachedCollection.rootDirs)
					Configuration.shared.addScannedDirectories(Configuration.shared.lookupFolders)
				}
				return
			}
		}
		internalStartScan()
	}
	
	func startScan(withConfirmation: Bool) {
		if let windowController = mainWindowController,
			parsedImageCollection == nil,
			withConfirmation && Configuration.shared.newScanMustBeConfirmed && windowController.hasContent
		{
			let scanCompletionHandler: (Bool) -> Void = { response in
				if response {
					self.internalStartScan()
				}
				else {
					windowController.isDragAndDropVisible = false
				}
			}
			self.confirmAction(NSLocalizedString("Are you sure you want to start a new scan?", comment: "Confirmation for starting new scan"),
							   forWindow: windowController.window,
							   action: scanCompletionHandler)
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
		popup.buttons[0].keyEquivalent = "\r"
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
		Configuration.shared.openedFileUrl = fileUrl
		do {
			// Parse scan database from file
			let parsedCollection = try JSONDecoder().decode(ImageCollection.self, from: Data(contentsOf: fileUrl))
			
			// Collect directories of this scan which weren't allowed by user yet
			notYetAllowedParsedDirs = []
			for path in parsedCollection.rootDirs {
				if !Configuration.shared.wasDirectoryScanned(path) {
					notYetAllowedParsedDirs.append(path)
				}
			}
			if notYetAllowedParsedDirs.count > 0 {
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
				for path in notYetAllowedParsedDirs {
					NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
				}
				// Remember this parse
				parsedImageCollection = parsedCollection
				// That's all for parsed scan for now
				return true
			}
			
			// All directories in this scan were allowed previously by user
			// no additional steps needed, just read scan and display it :)
			imageCollection = parsedCollection
			
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
	
	@discardableResult private func saveImageDatabase(_ fileUrl: URL, onError errorHandler: () -> Void) -> Bool {
		if let jsonData = try? JSONEncoder().encode(self.imageCollection) {
			do {
				try jsonData.write(to: fileUrl)
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
		if let fileUrl = Configuration.shared.openedFileUrl {
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
						Configuration.shared.openedFileUrl = fileUrl
					}
				}
			}
		})
	}
	
}
