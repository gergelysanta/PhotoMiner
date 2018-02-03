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
	var parsedImageCollection:ImageCollection?

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
			let imagesAvailable = self.imageCollection.count > 0
			if let scanning = mainWindowController?.scanner.isRunning {
				// Listing is available only when not scanning
				return scanning ? false : imagesAvailable
			}
			return imagesAvailable
		}
	}
	
	@objc dynamic var isSaveAvailable:Bool {
		get {
			return isListingAvailable && (Configuration.shared.openedFileUrl != nil)
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
		// Check if we have cached scan (loaded from pms file)
		if let cachedCollection = parsedImageCollection {
			if cachedCollection.rootDirs == Configuration.shared.lookupFolders {
				self.imageCollection = cachedCollection
				mainWindowController?.refreshPhotos()
				mainWindowController?.titlebarController?.progressOn(false)
				parsedImageCollection = nil
				Configuration.shared.addScannedDirectories(Configuration.shared.lookupFolders)
				return
			}
		}
		
		parsedImageCollection = nil
		
		let scanStarted = mainWindowController?.scanner.start(pathsToScan: Configuration.shared.lookupFolders,
															  bottomSizeLimit: Configuration.shared.ignoreImagesBelowSize) ?? false
		if scanStarted {
			Configuration.shared.addScannedDirectories(Configuration.shared.lookupFolders)
		}
		else {
			// TODO: Display Warning
		}
		mainWindowController?.titlebarController?.progressOn(true)
	}
	
	func startScan(withConfirmation: Bool) {
		if let windowController = mainWindowController,
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
			windowController.mainViewController?.confirmAction(NSLocalizedString("Are you sure you want to start a new scan?", comment: "Confirmation for starting new scan"),
															   action: scanCompletionHandler)
		}
		else {
			internalStartScan()
		}
	}
	
	// MARK: - Instance methods

	func displaySheet(withMessage message: String, andInformativeText infoText: String?, ofType type: NSAlert.Style, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
		let alert = NSAlert()
		alert.messageText = message
		alert.informativeText = infoText ?? ""
		alert.alertStyle = type
		alert.addButton(withTitle: "OK")
		alert.beginSheetModal(for: window) { (result) in
			completionHandler?()
		}
	}
	
	func displaySheet(withMessage message: String, ofType type: NSAlert.Style, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
		displaySheet(withMessage: message, andInformativeText: nil, ofType: type, forWindow: window, completionHandler: completionHandler)
	}
	
	@discardableResult func loadImageDatabase(_ fileUrl: URL, onError errorHandler: (() -> Void)? = nil) -> Bool {
		do {
			var notYetAllowedDirs = [String]()

			// Parse scan database from file
			parsedImageCollection = try JSONDecoder().decode(ImageCollection.self, from: Data(contentsOf: fileUrl))
			if let parsedCollection = parsedImageCollection {
				// Collect directories of this scan which weren't allowed by user yet
				for path in parsedCollection.rootDirs {
					if !Configuration.shared.wasDirectoryScanned(path) {
						notYetAllowedDirs.append(path)
					}
				}
				if notYetAllowedDirs.count > 0 {
					// Parsed scan contains at least one not yet allowed directory
					for path in notYetAllowedDirs {
						// Display information...
						if let window = mainWindowController?.window {
							self.displaySheet(withMessage: NSLocalizedString("\nAction needed for accessing directories", comment: "Action needed for accessing directories"),
											  andInformativeText: String.localizedStringWithFormat(NSLocalizedString("System do not allows to read directories which weren't opened through OpenDialog or Drag&Drop. Because of this we opened Finder for you with pre-selected directories. You need to Drag&Drop these directories to the application's window in order to give access. These directories are the following:\n\n%@", comment: "Action needed for accessing directories: details"), notYetAllowedDirs.joined(separator: "\n")),
											  ofType: .critical,
											  forWindow: window) {
												self.mainWindowController?.isDragAndDropVisible = false
											  }
						}
						else {
							mainWindowController?.isDragAndDropVisible = false
						}
						
						// ...and open Finder with preselected directory
						NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
					}
					// That's all for parsed scan for now
					return true
				}
				
				// All directories in this scan were allowed previously by user
				// no additional steps needed, just read scan and display it :)
				imageCollection = parsedCollection
				parsedImageCollection = nil
			}
			
			Configuration.shared.openedFileUrl = fileUrl
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
