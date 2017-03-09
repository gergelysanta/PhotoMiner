//
//  ThumbnailView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol ThumbnailViewDelegate {
	func thumbnailClicked(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData)
	func thumbnailRightClicked(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData)
	func thumbnailDragged(_ thumbnail: ThumbnailView, with event: NSEvent, image data: ImageData)
}

class ThumbnailView: NSCollectionViewItem {
	
	var delegate:ThumbnailViewDelegate? = nil
	
	private let unselectedFrameColor = NSColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
	private let selectedFrameColor = NSColor(red:0.27, green:0.65, blue:0.88, alpha:1.00)
	private let unselectedTextColor = NSColor.darkGray
	private let selectedTextColor = NSColor.white
	private let dragStartsAtDistance:CGFloat = 5.0
	
	private var clickPosition = NSZeroPoint
	private var dragging = false
	
	override var isSelected:Bool {
		didSet {
			updateBackground()
		}
	}
	
	override var representedObject:Any? {
		didSet {
			if let object = representedObject as? ImageData {
				object.setThumbnail()
				
				self.textField?.stringValue = object.imageName
				if let appDelegate = NSApp.delegate as? AppDelegate {
					if appDelegate.configuration.creationDateAsLabel {
						let formatter = DateFormatter()
						formatter.dateStyle = .medium
						formatter.timeStyle = .short
						self.textField?.stringValue = formatter.string(from: object.creationDate)
					}
				}
				self.imageView?.bind("value", to: object, withKeyPath: "imageThumbnail", options: nil)
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		view.wantsLayer = true
		view.layer?.backgroundColor = unselectedFrameColor.cgColor
		view.layer?.cornerRadius = 4.0
    }
	
	func updateBackground() {
		if isSelected {
			view.layer?.backgroundColor = selectedFrameColor.cgColor
			if let textField = textField {
				textField.textColor = selectedTextColor
			}
		}
		else {
			view.layer?.backgroundColor = unselectedFrameColor.cgColor
			if let textField = textField {
				textField.textColor = unselectedTextColor
			}
		}
	}
	
	// MARK: Mouse events
	//
	
	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)
		clickPosition = event.locationInWindow
		dragging = false
		if	let imageData = representedObject as? ImageData,
			let delegate = self.delegate
		{
			delegate.thumbnailClicked(self, with: event, image: imageData)
		}
	}
	
	override func mouseDragged(with event: NSEvent) {
		super.mouseDragged(with: event)
		if !dragging {
			let position = event.locationInWindow
			let distance = sqrt(pow(position.x-clickPosition.x, 2)+pow(position.y-clickPosition.y, 2))
			if distance > dragStartsAtDistance {
				dragging = true
				if	let imageData = representedObject as? ImageData,
					let delegate = self.delegate
				{
					delegate.thumbnailDragged(self, with: event, image: imageData)
				}
			}
		}
	}
	
	override func rightMouseDown(with event: NSEvent) {
		super.rightMouseDown(with: event)
		if	let imageData = representedObject as? ImageData,
			let delegate = self.delegate
		{
			delegate.thumbnailRightClicked(self, with: event, image: imageData)
		}
	}
	
}
