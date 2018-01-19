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
	
	var imageCollection = ImageCollection()
	
	var mainWindowController:MainWindowController? {
		get {
			return NSApp.mainWindow?.windowController as? MainWindowController
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
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		if Configuration.shared.setLookupDirectories([filename]) {
			mainWindowController?.startScan()
			return true
		}
		return false
	}
	
	func application(_ sender: NSApplication, openFiles filenames: [String]) {
		if Configuration.shared.setLookupDirectories(filenames) {
			mainWindowController?.startScan()
		}
	}
	
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
		openPanel.allowedFileTypes = [ "pmr" ]

		openPanel.beginSheetModal(for: window) { (response:NSApplication.ModalResponse) in
			if response == .OK {
				if let fileUrl = openPanel.url {
					do {
						self.imageCollection = try JSONDecoder().decode(ImageCollection.self, from: Data(contentsOf: fileUrl))
						self.mainWindowController?.refreshPhotos()
					} catch {
						openPanel.close()
						
						let alert = NSAlert()
						alert.messageText = "Couldn't parse scan from \(fileUrl.path)"
						alert.informativeText = "File is corrupted or it's not a scan result"
						alert.alertStyle = .critical
						alert.addButton(withTitle: "OK")
						alert.beginSheetModal(for: window)
					}
				}
			}
		}
	}
	
	@IBAction func saveMenuItemPressed(_ sender: NSMenuItem) {
		guard let window = mainWindowController?.window else { return }
		
		if let jsonData = try? JSONEncoder().encode(self.imageCollection) {

			let savePanel = NSSavePanel()
			savePanel.canCreateDirectories = true
			savePanel.allowedFileTypes = [ "pmr" ]

			savePanel.beginSheetModal(for: window, completionHandler: { (response:NSApplication.ModalResponse) in
				if response == .OK {
					if let fileUrl = savePanel.url {
						do {
							try jsonData.write(to: fileUrl)
						} catch {
							savePanel.close()

							let alert = NSAlert()
							alert.messageText = "Couldn't save scan to \(fileUrl.path)"
							alert.alertStyle = .critical
							alert.addButton(withTitle: "OK")
							alert.beginSheetModal(for: window)
						}
					}
				}
			})
		}
		else {
			let alert = NSAlert()
			alert.messageText = "Couldn't prepare data for saving"
			alert.alertStyle = .critical
			alert.addButton(withTitle: "OK")
			alert.beginSheetModal(for: window)
		}
	}
	
}

