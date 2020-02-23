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
	
	@IBOutlet private(set) var shadeView: ShadeView!

	@IBOutlet private var dropView: DropView!
	@IBOutlet private var dropDescription: NSTextField!
	
	@IBOutlet var thumbnailContextMenu: NSMenu!
	@IBOutlet var viewContextMenu: NSMenu!
	private var quickLookActive = false
	private var reloadHelperArray = [ImageData]()
	
	private var storyboardDescriptionString = ""
	
	static var instance:MainViewController?
	
	private var _dropViewVisible = true
	var isDropViewVisible:Bool {
		get {
			return !dropView.isHidden
		}
		set {
			_dropViewVisible = newValue
			if newValue || (dropDescription.stringValue != storyboardDescriptionString){
				dropView.show()
			} else {
				dropView.hide()
			}
		}
	}
	
	@objc dynamic var isJumpToSelectionAvailable: Bool {
		get {
			return (collectionView == nil) ? false : (collectionView.selectionIndexPaths.count > 0)
		}
	}
	
	var dropViewText:String? {
		get {
			return dropDescription.stringValue
		}
		set {
			if let stringValue = newValue {
				dropDescription.stringValue = stringValue
			}
			else {
				dropDescription.stringValue = storyboardDescriptionString
			}
			// Re-set visibility so dropview can he shown/hidden again
			isDropViewVisible = _dropViewVisible
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		MainViewController.instance = self
		view.wantsLayer = true
		if #available(OSX 10.12, *) {
			collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
		}
		shadeView.hide()
		collectionView.keyDelegate = self
		storyboardDescriptionString = dropDescription.stringValue
	}
	
	func imageAtIndexPath(indexPath:IndexPath) -> ImageData? {
		return AppData.shared.imageCollection.image(withIndexPath: indexPath)
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
				NSWorkspace.shared.selectFile(image.imagePath, inFileViewerRootedAtPath: "")
			}
		case 2:				// "Open"
			for image in self.selectedImages() {
				NSWorkspace.shared.openFile(image.imagePath)
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
		case 101:			// "Jump to selection"
			collectionView.selectItems(at: collectionView.selectionIndexPaths, scrollPosition: NSCollectionView.ScrollPosition.centeredVertically)
		default:
			NSLog("menuItem: UNKNOWN")
		}
		
		// Refresh QuickView if exists, it may contain picture which may changed
		if self.quickLookActive {
			QLPreviewPanel.shared().refreshCurrentPreviewItem()
		}
	}
	
	override func rightMouseDown(with event: NSEvent) {
		super.rightMouseDown(with: event)
		let locationInView = collectionView.convert(event.locationInWindow, from: collectionView.window?.contentView)
		if collectionView.indexPathForItem(at: locationInView) == nil {
			// Location is not above a thumbnail item, display view's context menu
			viewContextMenu.popUp(positioning: nil, at: event.locationInWindow, in: self.view)
		}
	}

	//
	// MARK: - Private methods
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
	
	private func trashImages(_ imagePathList:[String]) {
		guard imagePathList.count > 0 else { return }

		let trashCompletionHandler = { (response: Bool)->Void in
			if response {
				var imageURLs = [URL]()
				for imagePath in imagePathList {
					if FileManager.default.fileExists(atPath: imagePath) {
						// Image exists, cache for removal
						imageURLs.append(URL(fileURLWithPath: imagePath))
						// Mark imageset as changed
						AppData.shared.loadedImageSetChanged = true
					} else {
						// Image already removed from disk, remove it from listing
						AppData.shared.imageCollection.removeImage(withPath: imagePath)
						// Mark imageset as changed
						AppData.shared.loadedImageSetChanged = true
					}
				}
				
				// Trash all files cached for removal
				NSWorkspace.shared.recycle(imageURLs) { (trashedFiles, error) in
					for url in imageURLs where trashedFiles[url] != nil {
						AppData.shared.imageCollection.removeImage(withPath: url.path)
						
						if Configuration.shared.removeAlsoEmptyDirectories {
							FileManager.default.removeDirIfEmpty(url.deletingLastPathComponent())
						}
					}
					
					if let appDelegate = NSApp.delegate as? AppDelegate {
						// Refresh data thsough main window controller (this will refresh also titlebar)
						appDelegate.mainWindowController?.refreshPhotos()
					}
					else {
						// Refresh table (this won't refresh titlebar info, but at least table will reflect true information)
						self.collectionView.reloadData()
					}
					
					// TODO: Make this animated:
//					self.collectionView.performBatchUpdates({
//						self.collectionView.deleteItems(at: Set<IndexPath>)
//					}, completionHandler: { (result) in
//						NSLog("Complete: %@", result ? "OK" : "NO")
//					})
				}
			}
		}
		
		if Configuration.shared.removeMustBeConfirmed {
			if let appDelegate = NSApp.delegate as? AppDelegate {
				let question = (imagePathList.count > 1)
					? String.localizedStringWithFormat(NSLocalizedString("Are you sure you want to trash the selected %d pictures?", comment: "Confirmation for moving more pictures to trash"), imagePathList.count)
					: NSLocalizedString("Are you sure you want to trash the selected picture?", comment: "Confirmation for moving one picture to trash")
				appDelegate.confirmAction(question, forWindow: self.view.window, action: trashCompletionHandler)
			}
		}
		else {
			trashCompletionHandler(true)
		}
	}
	
	//
	// MARK: - QLPreviewPanelController methods
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

// MARK: - NSCollectionViewDataSource
extension MainViewController: NSCollectionViewDataSource {
	
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return AppData.shared.imageCollection.arrangedKeys.count
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if section < AppData.shared.imageCollection.arrangedKeys.count {
			let monthKey = AppData.shared.imageCollection.arrangedKeys[section]
			if let imagesOfMonth = AppData.shared.imageCollection.dictionary[monthKey] {
				return imagesOfMonth.count
			}
		}
		return 0
	}
	
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThumbnailViewItem"), for: indexPath) as! ThumbnailViewItem
		if let imageData = self.imageAtIndexPath(indexPath: indexPath) {
			imageData.parseImageProperties()
			item.representedObject = imageData
		}
		item.delegate = self
		return item
	}
	
	func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
		
		if kind != NSCollectionView.elementKindSectionHeader {
			let view = NSView()
			view.wantsLayer = true
			view.layer?.backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 0.2).cgColor
			view.layer?.borderColor = NSColor(calibratedWhite: 0.5, alpha: 0.5).cgColor
			view.layer?.borderWidth = 2.0
			view.layer?.cornerRadius = 5.0
			return view
		}
		
		let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader,
														withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderView"),
														for: indexPath)
		guard let headerView = view as? HeaderView else { return view }
		
		headerView.headerDelegate = self
		
		if indexPath.section < AppData.shared.imageCollection.arrangedKeys.count {
			let monthKey = AppData.shared.imageCollection.arrangedKeys[indexPath.section]
			
			let index = monthKey.index(monthKey.startIndex, offsetBy: 4)
			let yearStr = monthKey[..<index]
			let monthStr = monthKey[index...]
			
			headerView.setTitle(year: Int(yearStr)!, andMonth: Int(monthStr)!)
			
			if let imagesOfMonth = AppData.shared.imageCollection.dictionary[monthKey] {
				headerView.setPictureCount(imagesOfMonth.count)
			}
			else {
				headerView.setPictureCount(-1)
			}
		}
		
		return headerView
	}
	
	private func didSelectItems(_ indexPaths: Set<IndexPath>) {
		if let sidebarController = SidebarController.instance,
			let indexPath = indexPaths.first,
			let image = self.imageAtIndexPath(indexPath: indexPath)
		{
			sidebarController.imagePath = image.imagePath
			sidebarController.exifData = image.exifData
		}
		
		if self.quickLookActive {
			QLPreviewPanel.shared().reloadData()
		}
	}
	
}

// MARK: - NSCollectionViewDelegate
extension MainViewController: NSCollectionViewDelegate {
	
	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
		didSelectItems(indexPaths)
	}
	
	func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
		if let sidebarController = SidebarController.instance,
			let indexPath = indexPaths.first,
			let image = self.imageAtIndexPath(indexPath: indexPath)
		{
			if sidebarController.imagePath.compare(image.imagePath) == .orderedSame {
				sidebarController.imagePath = ""
				sidebarController.exifData = [:]
			}
		}
	}
	
	// The return value indicates whether the collection view can attempt to initiate a drag for the given event and items.
	// If the delegate does not implement this method, the collection view will act as if it returned YES.
	func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
		return true
	}
	
	// Dragging Source Support - Required for multi-image drag and drop. Return a custom object that implements
	// NSPasteboardWriting (or simply use NSPasteboardItem), or nil to prevent dragging for the item.
	// For each valid item returned, NSCollectionView will create an NSDraggingItem with the draggingFrame
	// equal to the frame of the item view at the given index path and components from
	// -[NSCollectionViewItem draggingItem].
	// If this method is implemented, then
	// -collectionView:writeItemsAtIndexPaths:toPasteboard: and
	// -collectionView:draggingImageForItemsAtIndexPaths:withEvent:offset: will not be called.
	func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
		if let image = self.imageAtIndexPath(indexPath: indexPath) {
			return NSURL(fileURLWithPath: image.imagePath)
		}
		return nil
	}
	
}

// MARK: - QLPreviewPanelDataSource
extension MainViewController: QLPreviewPanelDataSource {
	
	func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
		return self.selectedImages().count
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		let images = self.selectedImages()
		if index < images.count {
			return URL(fileURLWithPath: images[index].imagePath) as QLPreviewItem
		}
		return nil
	}
	
}

// MARK: - QLPreviewPanelDelegate
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

// MARK: - HeaderViewDelegate
extension MainViewController: HeaderViewDelegate {
	
	func headerToggleCollapse(_ headerView: HeaderView) {
		if #available(OSX 10.12, *) {
			collectionView.toggleSectionCollapse(headerView)
		}
	}
	
}

// MARK: - ThumbnailViewItemDelegate
extension MainViewController: ThumbnailViewItemDelegate {
	
	func thumbnailClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent) {
		if event.clickCount == 2 {
			// Doubleclick: Open in default app
			for image in self.selectedImages() {
				NSWorkspace.shared.openFile(image.imagePath)
			}
		}
	}
	
	func thumbnailRightClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent) {
		let viewLocation = collectionView.convert(event.locationInWindow, from: self.view)
		if let indexPath = collectionView.indexPathForItem(at: viewLocation) {
			var selectedItemRightClicked = false
			for selectedIndexPath in collectionView.selectionIndexPaths {
				if selectedIndexPath == indexPath {
					selectedItemRightClicked = true
				}
			}
			// Select item
			if !selectedItemRightClicked {
				collectionView.deselectAll(self)
				collectionView.selectItems(at: [indexPath], scrollPosition: [])
				self.didSelectItems([indexPath])
			}
		}
		// Display context menu
		thumbnailContextMenu.popUp(positioning: nil, at: event.locationInWindow, in: self.view)
	}
	
}

// MARK: - PhotoCollectionViewDelegate
extension MainViewController: PhotoCollectionViewDelegate {
	
	func keyPress(_ collectionView: PhotoCollectionView, with event: NSEvent) -> Bool {
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
	
	func preReloadData(_ collectionView: PhotoCollectionView) {
		reloadHelperArray = [ImageData]()
		for indexPath in collectionView.selectionIndexPaths {
			if	let item = collectionView.item(at: indexPath),
				let object = item.representedObject as? ImageData
			{
				reloadHelperArray.append(object)
			}
		}
	}
	
	func postReloadData(_ collectionView: PhotoCollectionView) {
		var indexPaths = Set<IndexPath>()
		
		for imageData in reloadHelperArray {
			if let indexPath = AppData.shared.imageCollection.indexPath(of: imageData) {
				indexPaths.insert(indexPath)
			}
		}
		if AppData.shared.imageCollection.count > 0 {
			dropView.hide()
		}
		else {
			dropView.show()
		}
		collectionView.selectItems(at: indexPaths, scrollPosition: [])
		self.didSelectItems(indexPaths)
	}
	
	func drag(_ collectionView: PhotoCollectionView, session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		if operation == .delete {
			// Dragging session ended with delete operation (user dragged the icon to the trash)
			if let pictureURLs:[NSURL] = session.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
				var filePathList = [String]()
				for pictureURL in pictureURLs {
					if let path = pictureURL.path {
						filePathList.append(path)
					}
				}
				self.trashImages(filePathList)
			}
		}
	}
	
}
