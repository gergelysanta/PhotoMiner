//
//  SettingsController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class SettingsController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	
	@IBOutlet weak var tableView: NSTableView!
	
	var configuration:Configuration? {
		get {
			if let appDelegate = NSApp.delegate as? AppDelegate {
				return appDelegate.configuration
			}
			return nil
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func dismiss(_ sender: Any?) {
		super.dismiss(sender)
		if	let appDelegate = NSApp.delegate as? AppDelegate,
			let mainWindowController = appDelegate.mainWindowController,
			let mainViewController = mainWindowController.window?.contentViewController as? MainViewController
		{
			// Reftesh collectionView
			mainViewController.collectionView.reloadData()
		}
	}
	
	@IBAction func addItemButtonPressed(_ sender: Any) {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			let dialog = NSOpenPanel();
			
			dialog.showsHiddenFiles			= false
			dialog.canChooseDirectories		= true
			dialog.canChooseFiles			= false
			dialog.allowsMultipleSelection	= false
			
			let successBlock: (Int) -> Void = { response in
				if response == NSFileHandlingPanelOKButton {
					if let result = dialog.url {
						appDelegate.configuration.lookupFolders.append(result.path)
						appDelegate.configuration.saveConfiguration()
						self.tableView.reloadData()
					}
				}
			}
			
			if let window = self.view.window {
				dialog.beginSheetModal(for: window, completionHandler: successBlock)
			}
			else {
				dialog.begin(completionHandler: successBlock)
			}
		}
	}
	
	@IBAction func removeItemButtonPressed(_ sender: Any) {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			tableView.selectedRowIndexes.forEach({ index in
				appDelegate.configuration.lookupFolders.remove(at: index)
				appDelegate.configuration.saveConfiguration()
				tableView.reloadData()
			})
		}
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
	
	func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
		if let newPath = object as? String {
			if let appDelegate = NSApp.delegate as? AppDelegate {
				appDelegate.configuration.lookupFolders[row] = newPath
				appDelegate.configuration.saveConfiguration()
			}
		}
	}
	
	// MARK: NSTableViewDelegate methods
	
}
