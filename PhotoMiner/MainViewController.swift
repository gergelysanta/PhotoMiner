//
//  MainViewController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController, NSCollectionViewDataSource {
	
	@IBOutlet weak var collectionView: NSCollectionView!
	
	@IBOutlet var contextMenu: NSMenu!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.wantsLayer = true
	}
	
	//
	// MARK: NSCollectionViewDataSource methods
	//
	
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			return appDelegate.scannedFiles.count
		}
		return 0
	}
	
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: "ThumbnailView", for: indexPath)
		
		if let appDelegate = NSApp.delegate as? AppDelegate {
			item.representedObject = appDelegate.scannedFiles[indexPath.item]
		}
		
		return item
	}
	
	// Context menu actions
	
	@IBAction func contextMenuItemSelected(_ sender: NSMenuItem) {
		switch sender.tag {
		case 1:				// "Show in Finder"
			NSLog("menuItem: Show in Finder")
		case 2:				// "Open"
			NSLog("menuItem: Open")
		case 3:				// "Quick Look"
			NSLog("menuItem: Quick Look")
		case 10:			// "Move to Trash"
			NSLog("menuItem: Move to Trash")
		default:
			NSLog("menuItem: UNKNOWN")
		}
	}
	
	// Displaying context menu
	
	func displayContextMenu(forData data: ImageData, atLocation location: NSPoint) {
		let viewLocation = collectionView.convert(location, from: self.view)
		if let indexPath = collectionView.indexPathForItem(at: viewLocation) {
			// Select item
			if collectionView.selectionIndexPaths.count <= 1 {
				collectionView.deselectAll(self)
				collectionView.selectItems(at: [indexPath], scrollPosition: [])
			}
		}
		// Display context menu
		contextMenu.popUp(positioning: nil, at: location, in: self.view)
	}
	
}
