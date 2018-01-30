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
			return loadImageDatabase(URL(fileURLWithPath: filename), onError: {})
		}
		else if Configuration.shared.setLookupDirectories([filename]) {
			mainWindowController?.startScan()
			return true
		}
		return false
	}
	
	func application(_ sender: NSApplication, openFiles filenames: [String]) {
		let savedDataFiles = filenames.filter { $0.hasSuffix(".\(Configuration.shared.saveDataExtension)") }
		if savedDataFiles.count > 0 {
			for filename in savedDataFiles {
				if loadImageDatabase(URL(fileURLWithPath: filename), onError: {}) {
					return
				}
			}
		}
		else if Configuration.shared.setLookupDirectories(filenames) {
			mainWindowController?.startScan()
		}
	}
	
	// MARK: - Instance methods

	func displayErrorSheet(withMessage message: String, andInformativeText infoText: String?, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
		let alert = NSAlert()
		alert.messageText = message
		alert.informativeText = infoText ?? ""
		alert.alertStyle = .critical
		alert.addButton(withTitle: "OK")
		alert.beginSheetModal(for: window) { (result) in
			completionHandler?()
		}
	}
	
	func displayErrorSheet(withMessage message: String, forWindow window: NSWindow, completionHandler: (() -> Void)? = nil) {
		displayErrorSheet(withMessage: message, andInformativeText: nil, forWindow: window, completionHandler: completionHandler)
	}
	
	private func promptUserForDirs(_ directories: [String]) {
		guard let window = mainWindowController?.window else { return }
		
		func promptForDirs(_ directories: [String]) {
			guard let directory = directories.first else { return }
			
			let openPanel = NSOpenPanel()
			openPanel.allowsMultipleSelection = false
			openPanel.canChooseDirectories = true
			openPanel.canCreateDirectories = false
			openPanel.canChooseFiles = false
			openPanel.directoryURL = URL(fileURLWithPath: directory)
			openPanel.beginSheetModal(for: window) { (result) in
				if directories.count > 1 {
					// There're more directories to confirm, proceed with the following ones
					promptForDirs(Array(directories.dropFirst()))
				}
				else {
					// Refresh collection view even when user clicked 'Cancel'
					// Image collection will be loaded in both cases, just after 'Cancel' they'll have blank thumbnails
					// This indicates that something went wrong
					self.mainWindowController?.refreshPhotos()
				}
			}
		}
		
		// Display message about prompting for loaded directories
		let alert = NSAlert()
		if directories.count > 1 {
			alert.messageText = NSLocalizedString("You need to allow access to all scanned directories", comment: "Allow access to all scanned directories")
			alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("In the following step you'll be asked to open all directories in this scan in order to get access to the scanned pictures. These are:\n%@", comment: "Allow access to all scanned directory explanation"), directories.joined(separator: "\n"))
		}
		else {
			alert.messageText = NSLocalizedString("You need to allow access to scanned directory", comment: "Allow access to scanned directory")
			alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("In the following step you'll be asked to open the following directory in order to get access to the scanned pictures:\n%@", comment: "Allow access to scanned directory explanation"), directories.first ?? "<none>")
		}
		alert.alertStyle = .informational
		alert.addButton(withTitle: "OK")
		alert.beginSheetModal(for: window) { (result) in
			promptForDirs(directories)
		}
	}
	
	@discardableResult func loadImageDatabase(_ fileUrl: URL, onError errorHandler: () -> Void) -> Bool {
		do {
			self.imageCollection = try JSONDecoder().decode(ImageCollection.self, from: Data(contentsOf: fileUrl))
			Configuration.shared.openedFileUrl = fileUrl
			promptUserForDirs(self.imageCollection.rootDirs)
			return true
		} catch {
			errorHandler()
			if let window = mainWindowController?.window {
				self.displayErrorSheet(withMessage: String.localizedStringWithFormat(NSLocalizedString("Couldn't parse scan from %@", comment: "Couldn't parse scan from file"), fileUrl.path),
									   andInformativeText: NSLocalizedString("File is corrupted or it's not a scan result", comment: "File is corrupted or it's not a scan result"),
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
					displayErrorSheet(withMessage: String.localizedStringWithFormat(NSLocalizedString("Couldn't save scan to %@", comment: "Couldn't save scan to file"), fileUrl.path),
					                    forWindow: window)
				}
			}
		}
		else {
			errorHandler()
			if let window = mainWindowController?.window {
				displayErrorSheet(withMessage: NSLocalizedString("Couldn't prepare data for saving", comment: "Couldn't prepare data for saving"), forWindow: window)
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
