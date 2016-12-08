//
//  SettingsController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class SettingsController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	// MARK: NSTableViewDataSource methods
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			return appDelegate.configuration.lookupFolders.count
		}
		return 0
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			return appDelegate.configuration.lookupFolders[row]
		}
		return nil
	}
	
	// MARK: NSTableViewDelegate methods
	
}
