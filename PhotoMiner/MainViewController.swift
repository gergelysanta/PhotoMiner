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
	
	func selectedImages() -> [ImageData] {
		var imageArray = [ImageData]()
		
		for indexPath in collectionView.selectionIndexPaths {
			if let image = self.imageAtIndexPath(indexPath: indexPath) {
				imageArray.append(image)
			}
		}
		
		return imageArray
	}
	
	@IBAction func contextMenuItemSelected(_ sender: NSMenuItem) {
		switch sender.tag {
		case 1:				// "Show in Finder"
			for image in self.selectedImages() {
				NSWorkspace.shared().selectFile(image.imagePath, inFileViewerRootedAtPath: "")
			}
		case 2:				// "Open"
			for image in self.selectedImages() {
				NSWorkspace.shared().openFile(image.imagePath)
			}
		case 3:				// "Quick Look"
			QLPreviewPanel.shared().makeKeyAndOrderFront(self)
			
			// --------------------------------------------------------
			
		case 11:			// "Move to Trash"
			let selectedImages = self.selectedImages()
			let question = (selectedImages.count > 1)
								? String.localizedStringWithFormat(NSLocalizedString("Are you sure you want to trash the selected %d pictures?", comment: "Confirmation for moving more pictures to trash"), selectedImages.count)
								: NSLocalizedString("Are you sure you want to trash the selected picture?", comment: "Confirmation for moving one picture to trash")
			self.confirmAction(question) {
				self.trashImages(selectedImages)
			}
			
			// --------------------------------------------------------
			
		case 21:			// "Rotate Left"
			for image in self.selectedImages() {
				self.executeSipsWithArgs(["-r", "270", image.imagePath])
				image.setThumbnail()
			}
		case 22:			// "Rotate Right"
			for image in self.selectedImages() {
				self.executeSipsWithArgs(["-r", "90", image.imagePath])
				image.setThumbnail()
			}
		case 23:			// "Flip Horizontal"
			for image in self.selectedImages() {
				self.executeSipsWithArgs(["-f", "horizontal", image.imagePath])
				image.setThumbnail()
			}
		case 24:			// "Flip Vertical"
			for image in self.selectedImages() {
				self.executeSipsWithArgs(["-f", "vertical", image.imagePath])
				image.setThumbnail()
			}
		default:
			NSLog("menuItem: UNKNOWN")
		}
		
		// Refresh QuickView if exists, it may contain picture which may changed
		if QLPreviewPanel.sharedPreviewPanelExists() {
			QLPreviewPanel.shared().refreshCurrentPreviewItem()
		}
	}
	
	
	//
	// MARK: Private methods
	//
	
	@discardableResult private func executeSipsWithArgs(_ args:[String]) -> Bool {
		let process = Process()
		process.launchPath = "/usr/bin/sips"
		process.arguments = args
		
		// We don't need output from the string, so make it silent (forward output to pipes we won't read)
		process.standardOutput = Pipe()
		process.standardError = Pipe()
		
		process.launch()
		process.waitUntilExit()
		if process.terminationStatus != 0 {
			return false
		}
		return true
	}
	
	private func trashImages(_ imageArray:[ImageData]) {
		var imageURLs = [URL]()
		
		if let appDelegate = NSApp.delegate as? AppDelegate {
			for image in imageArray {
				imageURLs.append(URL(fileURLWithPath: image.imagePath))
			}
			
			NSWorkspace.shared().recycle(imageURLs) { (trashedFiles, error) in
				for url in imageURLs where trashedFiles[url] != nil {
					_ = appDelegate.imageCollection.removeImage(withPath: url.path)
				}
				self.collectionView.reloadData()
			}
		}
	}
	
	private func confirmAction(_ question: String, action: @escaping (() -> Swift.Void)) {
		let popup: NSAlert = NSAlert()
		popup.messageText = question
		popup.informativeText = ""
		popup.alertStyle = NSAlertStyle.warning
		popup.addButton(withTitle: NSLocalizedString("No", comment: "No"))
		popup.addButton(withTitle: NSLocalizedString("Yes", comment: "Yes"))
		if let window = self.view.window {
			popup.beginSheetModal(for: window) { (response) in
				if response == NSAlertSecondButtonReturn {
					action()
				}
			}
		}
		else {
			if popup.runModal() == NSAlertSecondButtonReturn {
				action()
			}
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
				
				headerView.setTitle(fromYear: Int(yearStr)!, andMonth: Int(monthStr)!)
				
				if let imagesOfMonth = appDelegate.imageCollection.dictionary[monthKey] {
					headerView.sectionInfo.stringValue = String.localizedStringWithFormat(NSLocalizedString("%d pictures", comment: "Section header info: pictures count"), imagesOfMonth.count)
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
		return self.selectedImages().count
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		let images = self.selectedImages()
		if index < images.count {
			return URL(fileURLWithPath: images[index].imagePath) as QLPreviewItem!
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
		for image in self.selectedImages() {
			NSWorkspace.shared().openFile(image.imagePath)
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
