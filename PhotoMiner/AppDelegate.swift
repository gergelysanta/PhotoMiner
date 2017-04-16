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
	
}

