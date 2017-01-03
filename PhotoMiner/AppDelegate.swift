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
	
	let configuration = Configuration()
	var scannedFiles = [ImageData]()
	
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
	
}

