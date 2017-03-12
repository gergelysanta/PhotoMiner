//
//  MainViewController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa
import Quartz

class MainViewController: NSViewController {
	
	@IBOutlet weak var collectionView: PhotoCollectionView!
	@IBOutlet weak var collectionViewFlowLayout: NSCollectionViewFlowLayout!
	
	@IBOutlet var contextMenu: NSMenu!
	fileprivate var quickLookActive = false
	
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
			return appDelegate.imageCollection.image(withIndexPath: indexPath)
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
			
			var filePathList = [String]()
			for image in self.selectedImages() {
				filePathList.append(image.imagePath)
			}
			self.trashImages(filePathList)
			
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
	
	fileprivate func trashImages(_ imagePathList:[String]) {
		guard imagePathList.count > 0 else { return }
		guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
		
		func removeDirURLIfEmpty(_ dirUrl: URL) {
			do {
				let files = try FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants])
				if	(files.count == 0) ||
					((files.count == 1) && (files.first!.lastPathComponent == ".DS_Store"))
				{
					try FileManager.default.removeItem(at: dirUrl)
					removeDirURLIfEmpty(dirUrl.deletingLastPathComponent())
				}
			} catch {
			}
		}
		
		let trashCompletionHandler: ()->Void = {
			var imageURLs = [URL]()
			for imagePath in imagePathList {
				imageURLs.append(URL(fileURLWithPath: imagePath))
			}
			
			NSWorkspace.shared().recycle(imageURLs) { (trashedFiles, error) in
				for url in imageURLs where trashedFiles[url] != nil {
					_ = appDelegate.imageCollection.removeImage(withPath: url.path)
					
					if appDelegate.configuration.removeAlsoEmptyDirectories {
						removeDirURLIfEmpty(url.deletingLastPathComponent())
					}
				}
				self.collectionView.reloadData()
				
				// TODO: Make this animated:
//				self.collectionView.performBatchUpdates({
//					self.collectionView.deleteItems(at: Set<IndexPath>)
//				}, completionHandler: { (result) in
//					NSLog("Complete: %@", result ? "OK" : "NO")
//				})
			}
		}
		
		if appDelegate.configuration.removeMustBeConfirmed {
			let question = (imagePathList.count > 1)
				? String.localizedStringWithFormat(NSLocalizedString("Are you sure you want to trash the selected %d pictures?", comment: "Confirmation for moving more pictures to trash"), imagePathList.count)
				: NSLocalizedString("Are you sure you want to trash the selected picture?", comment: "Confirmation for moving one picture to trash")
			self.confirmAction(question, action: trashCompletionHandler)
		}
		else {
			trashCompletionHandler()
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
	
}

// MARK: NSCollectionViewDataSource extension
extension MainViewController: NSCollectionViewDataSource {
	
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
		if let imageData = self.imageAtIndexPath(indexPath: indexPath) {
			imageData.frame = item.view.frame
			item.representedObject = imageData
		}
		item.delegate = self
		return item
	}
	
	func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
		
		if kind != NSCollectionElementKindSectionHeader {
			let view = NSView()
			view.wantsLayer = true
			view.layer?.backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 0.2).cgColor
			view.layer?.borderColor = NSColor(calibratedWhite: 0.5, alpha: 0.5).cgColor
			view.layer?.borderWidth = 2.0
			view.layer?.cornerRadius = 5.0
			return view
		}
		
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
					let countLabel = (imagesOfMonth.count > 1)
						? NSLocalizedString("pictures", comment: "Picture count: >1 pictures")
						: NSLocalizedString("picture", comment: "Picture count: 1 picture")
					headerView.sectionInfo.stringValue = String(format: "%d %@", imagesOfMonth.count, countLabel)
				}
				else {
					headerView.sectionInfo.stringValue = ""
				}
			}
		}
		
		return headerView
	}
	
}

// MARK: NSCollectionViewDelegate extension
extension MainViewController: NSCollectionViewDelegate {
	
	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
		if self.quickLookActive {
			QLPreviewPanel.shared().reloadData()
		}
	}
	
}

// MARK: NSDraggingSource extension
extension MainViewController: NSDraggingSource {
	
	func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
		switch(context) {
			case .outsideApplication:
				return [ .copy, .link, .generic, .delete ]
			case .withinApplication:
				return .move
		}
	}
	
	func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		if operation == .delete {
			// Dragging session ended with delete operation (user dragged the icon to the trash)
			if let filePathList = session.draggingPasteboard.propertyList(forType: NSFilenamesPboardType) as? [String] {
				self.trashImages(filePathList)
			}
		}
	}
	
}

// MARK: QLPreviewPanelDataSource extension
extension MainViewController: QLPreviewPanelDataSource {
	
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
	
}

// MARK: QLPreviewPanelDelegate extension
extension MainViewController: QLPreviewPanelDelegate {
	
	func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
		if event.type == .keyDown {
			collectionView.keyDown(with: event)
			return true
		}
		if event.type == .keyUp {
			collectionView.keyUp(with: event)
			return true
		}
		return false
	}
	
}

// MARK: ThumbnailViewDelegate extension
extension MainViewController: ThumbnailViewDelegate {
	
	private func renderItemToImage(_ thumbnail: ThumbnailView) -> NSImage? {
		
		if let bmpImageRep = thumbnail.view.bitmapImageRepForCachingDisplay(in: thumbnail.view.bounds) {
			thumbnail.view.cacheDisplay(in: thumbnail.view.bounds, to: bmpImageRep)
			
			let image = NSImage(size: thumbnail.view.bounds.size)
			image.addRepresentation(bmpImageRep)
			
			return image
		}
		return nil
	}
	
	private func renderSelectionToImage(_ thumbnail: ThumbnailView) -> (position: NSPoint, image: NSImage)? {
		if (collectionView.selectionIndexPaths.count == 1),
		   let thumbnailIndexPath = collectionView.indexPath(for: thumbnail),
		   (thumbnailIndexPath == collectionView.selectionIndexPaths.first!)
		{
			// There's only one item selected and thats the thumbnail we got as argument
			if let item = self.renderItemToImage(thumbnail) {
				return (NSZeroPoint, item)
			}
			return nil
		}
		
		// There're more items selected, render images for all of them
		// First count the frame size needed for all selected items and create/collect all drop images
		var itemsArray = [(item: ThumbnailView, image: NSImage)]()
		var fullFrame = NSMakeRect(9999, 9999, 0, 0)
		
		// Get maximum height of all screens
		var screenHeight:CGFloat = 0.0
		if let allScreens = NSScreen.screens() {
			for screen in allScreens {
				screenHeight = max(screenHeight, screen.frame.size.height)
			}
		}
		NSLog("Screen height: \(screenHeight)")
		
		for indexPath in collectionView.selectionIndexPaths {
			if let item = collectionView.item(at: indexPath) as? ThumbnailView {
				// Item is onscreen, we can render it to a view
				if let itemImage = self.renderItemToImage(item) {
					// We use x and y for counting minX and minY
					fullFrame.origin.x = min(fullFrame.origin.x, item.view.frame.origin.x)
					fullFrame.origin.y = min(fullFrame.origin.y, item.view.frame.origin.y)
					// We use width and height for counting maxX and maxY
					fullFrame.size.width = max(fullFrame.size.width, item.view.frame.origin.x + item.view.frame.size.width)
					fullFrame.size.height = max(fullFrame.size.height, item.view.frame.origin.y + item.view.frame.size.height)
				
					itemsArray.append( (item: item, image: itemImage) )
				}
			}
			else {
				// Item is offscreen, we have to create a ViewItem for it first, then render
				
				if let imageData = self.imageAtIndexPath(indexPath: indexPath) {
					// Skip this item if it's too far away from dragged item
					if (imageData.frame == NSZeroRect) || (abs(imageData.frame.origin.y - thumbnail.view.frame.origin.y) >= screenHeight) {
						continue
					}
					
					if let item = ThumbnailView(nibName: "ThumbnailView", bundle: nil)
					{
						// Initialize ViewItem for rendering
						item.representedObject = imageData
						item.view.frame = imageData.frame
						item.isSelected = true
						
						// Render it's view
						if let itemImage = self.renderItemToImage(item) {
							// We use x and y for counting minX and minY
							fullFrame.origin.x = min(fullFrame.origin.x, item.view.frame.origin.x)
							fullFrame.origin.y = min(fullFrame.origin.y, item.view.frame.origin.y)
							// We use width and height for counting maxX and maxY
							fullFrame.size.width = max(fullFrame.size.width, item.view.frame.origin.x + item.view.frame.size.width)
							fullFrame.size.height = max(fullFrame.size.height, item.view.frame.origin.y + item.view.frame.size.height)
							
							itemsArray.append( (item: item, image: itemImage) )
						}
					}
				}
			}
		}
		
		// Counting real full frame
		fullFrame.size.width = fullFrame.size.width - fullFrame.origin.x
		fullFrame.size.height = fullFrame.size.height - fullFrame.origin.y
		
		// Drawing image containing all selected items
		let image = NSImage(size: fullFrame.size)
		var thumbnailPos = NSZeroPoint
		image.lockFocus()
		for i in 0..<itemsArray.count {
			let itemFrame = itemsArray[i].item.view.frame
			let itemPos = NSPoint(x: itemFrame.origin.x - fullFrame.origin.x, y: fullFrame.origin.y + fullFrame.size.height - (itemFrame.origin.y + itemFrame.size.height))
			
			if thumbnail == itemsArray[i].item {
				thumbnailPos = itemPos
			}
			
			itemsArray[i].image.draw(at: itemPos, from: NSZeroRect, operation: NSCompositeSourceOver, fraction: 1.0)
		}
		image.unlockFocus()
	
		return (thumbnailPos, image)
	}
	
	func thumbnailClicked(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData) {
		if event.clickCount == 2 {
			// Doubleclick: Open in default app
			for image in self.selectedImages() {
				NSWorkspace.shared().openFile(image.imagePath)
			}
		}
	}
	
	func thumbnailDragged(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData) {
		var filePathList = [String]()
		for image in self.selectedImages() {
			filePathList.append(image.imagePath)
		}
		
		if let dragImage = self.renderSelectionToImage(thumbnail) {
			let dragPosition = self.view.convert(event.locationInWindow, from: nil)
			let positionInThumbnail = thumbnail.view.convert(event.locationInWindow, from: nil)
			let position = NSMakePoint(dragPosition.x - positionInThumbnail.x - dragImage.position.x, dragPosition.y - positionInThumbnail.y - dragImage.position.y)
			
			let pasteBoard = NSPasteboard(name: NSDragPboard)
			pasteBoard.declareTypes([NSFilenamesPboardType], owner: nil)
			pasteBoard.setPropertyList(filePathList, forType: NSFilenamesPboardType)
			
			self.view.window?.drag(dragImage.image, at: position, offset: NSZeroSize, event: event, pasteboard: pasteBoard, source: self, slideBack: true)
		}
	}
	
	func thumbnailRightClicked(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData) {
		let viewLocation = collectionView.convert(event.locationInWindow, from: self.view)
		if let indexPath = collectionView.indexPathForItem(at: viewLocation) {
			// Select item
			if collectionView.selectionIndexPaths.count <= 1 {
				collectionView.deselectAll(self)
				collectionView.selectItems(at: [indexPath], scrollPosition: [])
			}
		}
		// Display context menu
		contextMenu.popUp(positioning: nil, at: event.locationInWindow, in: self.view)
	}
	
}

// MARK: PhotoCollectionViewDelegate extension
extension MainViewController: PhotoCollectionViewDelegate {
	
	func collectionViewKeyPress(with event: NSEvent) -> Bool {
		switch event.keyCode {
		case 49:	// SPACE
			if self.quickLookActive {
				QLPreviewPanel.shared().close()
			} else {
				QLPreviewPanel.shared().makeKeyAndOrderFront(self)
			}
			return true
		case 51, 117:	// Backspace, Delete
			var filePathList = [String]()
			for image in self.selectedImages() {
				filePathList.append(image.imagePath)
			}
			self.trashImages(filePathList)
			return true
		default:
			return false
		}
	}
	
}
