//
//  MainViewController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa
import Quartz

class MainViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, ThumnailViewDelegate, PhotoCollectionViewDelegate {
	
	@IBOutlet weak var collectionView: PhotoCollectionView!
	@IBOutlet weak var collectionViewFlowLayout: NSCollectionViewFlowLayout!
	
	@IBOutlet var contextMenu: NSMenu!
	private var quickLookActive = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.wantsLayer = true
		if #available(OSX 10.12, *) {
			collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
		}
		collectionView.keyDelegate = self
	}
	
	func imageAtIndexPath(indexPath:IndexPath) -> ImageData? {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			if indexPath.section < appDelegate.imageCollection.arrangedKeys.count {
				let monthKey = appDelegate.imageCollection.arrangedKeys[indexPath.section]
				if let imagesOfMonth = appDelegate.imageCollection.dictionary[monthKey] {
					if indexPath.item < imagesOfMonth.count {
						return imagesOfMonth[indexPath.item]
					}
				}
			}
		}
		return nil
	}
	
	func selectedImagePaths() -> [String] {
		var pathArray = [String]()
		
		for indexPath in collectionView.selectionIndexPaths {
			if let image = self.imageAtIndexPath(indexPath: indexPath) {
				pathArray.append(image.imagePath)
			}
		}
		
		return pathArray
	}
	
	@IBAction func contextMenuItemSelected(_ sender: NSMenuItem) {
		switch sender.tag {
		case 1:				// "Show in Finder"
			for imagePath in self.selectedImagePaths() {
				NSWorkspace.shared().selectFile(imagePath, inFileViewerRootedAtPath: "")
			}
		case 2:				// "Open"
			NSLog("menuItem: Open")
			for imagePath in self.selectedImagePaths() {
				NSWorkspace.shared().openFile(imagePath)
			}
		case 3:				// "Quick Look"
			QLPreviewPanel.shared().makeKeyAndOrderFront(self)
		case 10:			// "Move to Trash"
			NSLog("menuItem: Move to Trash")
		default:
			NSLog("menuItem: UNKNOWN")
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
		let item = collectionView.makeItem(withIdentifier: "ThumbnailView", for: indexPath) as! ThumbnailView
		item.representedObject = self.imageAtIndexPath(indexPath: indexPath)
		item.delegate = self
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
	
	//
	// MARK: NSCollectionViewDelegate methods
	//
	
	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
		if self.quickLookActive {
			QLPreviewPanel.shared().reloadData()
		}
	}
	
	//
	// MARK: QLPreviewPanelController methods
	//
	
	override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.delegate = self
		panel.dataSource = self
		self.quickLookActive = true
	}
	
	override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
		self.quickLookActive = false
	}
	
	//
	// MARK: QLPreviewPanelDataSource methods
	//
	
	func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
		return self.selectedImagePaths().count
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		let imagePaths = self.selectedImagePaths()
		if index < imagePaths.count {
			return URL(fileURLWithPath: imagePaths[index]) as QLPreviewItem!
		}
		return nil
	}
	
	//
	// MARK: QLPreviewPanelDelegate methods
	//

	func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
		if event.type == .keyDown {
			self.keyDown(with: event)
		}
		else if event.type == .keyUp {
			self.keyUp(with: event)
		}
		return false
	}
	
	//
	// MARK: ThumbnailViewDelegate methods
	//
	
	func thumbnailDoubleClicked(image: ImageData) {
		// Open in default app
		for imagePath in self.selectedImagePaths() {
			NSWorkspace.shared().openFile(imagePath)
		}
	}
	
	func thumbnailRightClicked(image: ImageData, atLocation location: NSPoint) {
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
	
	//
	// MARK: PhotoCollectionViewDelegate methods
	//
	
	func collectionViewKeyPress(with event: NSEvent) {
		if event.keyCode == 49 {
			if quickLookActive {
				QLPreviewPanel.shared().close()
			} else {
				QLPreviewPanel.shared().makeKeyAndOrderFront(self)
			}
		}
	}
	
}
