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
	@IBOutlet weak var collectionViewFlowLayout: NSCollectionViewFlowLayout!
	
	@IBOutlet var contextMenu: NSMenu!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.wantsLayer = true
		if #available(OSX 10.12, *) {
			collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
		}
	}
	
	//
	// MARK: NSCollectionViewDataSource methods
	//
	
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			return appDelegate.imageCollection.arrangedKeys.count
		}
		return 0
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			if section < appDelegate.imageCollection.arrangedKeys.count {
				let monthKey = appDelegate.imageCollection.arrangedKeys[section]
				if let imagesOfMonth = appDelegate.imageCollection.dictionary[monthKey] {
					return imagesOfMonth.count
				}
			}
		}
		return 0
	}
	
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: "ThumbnailView", for: indexPath)
		
		if let appDelegate = NSApp.delegate as? AppDelegate {
			if indexPath.section < appDelegate.imageCollection.arrangedKeys.count {
				let monthKey = appDelegate.imageCollection.arrangedKeys[indexPath.section]
				if let imagesOfMonth = appDelegate.imageCollection.dictionary[monthKey] {
					if indexPath.item < imagesOfMonth.count {
						item.representedObject = imagesOfMonth[indexPath.item]
					}
				}
			}
		}
		
		return item
	}
	
	func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
		
		let view = collectionView.makeSupplementaryView(ofKind: NSCollectionElementKindSectionHeader, withIdentifier: "HeaderView", for: indexPath)
		guard let headerView = view as? HeaderView else { return view }
		
		if let appDelegate = NSApp.delegate as? AppDelegate {
			if indexPath.section < appDelegate.imageCollection.arrangedKeys.count {
				let monthKey = appDelegate.imageCollection.arrangedKeys[indexPath.section]
				
				let index = monthKey.index(monthKey.startIndex, offsetBy: 4)
				let yearStr = monthKey.substring(to: index)
				let monthStr = monthKey.substring(from: index)
				var month = ""
				switch (Int(monthStr)!) {
					case 1:
						month = "January";
					case 2:
						month = "February";
					case 3:
						month = "March";
					case 4:
						month = "April";
					case 5:
						month = "May";
					case 6:
						month = "June";
					case 7:
						month = "July";
					case 8:
						month = "August";
					case 9:
						month = "September";
					case 10:
						month = "October";
					case 11:
						month = "November";
					case 12:
						month = "December";
					default:
						month = "Unknown month";
				}
				headerView.sectionTitle.stringValue = "\(yearStr) \(month)"
				
				if let imagesOfMonth = appDelegate.imageCollection.dictionary[monthKey] {
					headerView.sectionInfo.stringValue = "\(imagesOfMonth.count) pictures"
				}
				else {
					headerView.sectionInfo.stringValue = ""
				}
			}
		}
		
		return headerView
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
