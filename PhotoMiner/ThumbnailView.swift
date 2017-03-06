//
//  ThumbnailView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol ThumnailViewDelegate {
	func thumbnailDoubleClicked(image: ImageData)
	func thumbnailRightClicked(image: ImageData, atLocation location: NSPoint)
}

class ThumbnailView: NSCollectionViewItem {
	
	var delegate:ThumnailViewDelegate? = nil
	
	private let unselectedFrameColor = NSColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
	private let selectedFrameColor = NSColor(red:0.27, green:0.65, blue:0.88, alpha:1.00)
	private let unselectedTextColor = NSColor.darkGray
	private let selectedTextColor = NSColor.white
	
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
//				self.textField?.bind("value", to: object, withKeyPath: "imageName", options: nil)
				self.imageView?.bind("value", to: object, withKeyPath: "imageThumbnail", options: nil)
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		view.wantsLayer = true
		view.layer?.backgroundColor = unselectedFrameColor.cgColor
		view.layer?.cornerRadius = 4.0
		
//		if let imageView = imageView {
//			imageView.layer?.backgroundColor = NSColor.white.cgColor
//		}
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
	
	//
	// MARK: Mouse events
	//
	
	override func mouseDown(with event: NSEvent) {
		if event.clickCount == 2 {
			if let object = representedObject as? ImageData {
				if let delegate = self.delegate {
					delegate.thumbnailDoubleClicked(image: object)
				}
			}
		}
		else {
			super.mouseDown(with: event)
		}
	}
	
	override func rightMouseDown(with event: NSEvent) {
		if let object = representedObject as? ImageData {
			if let delegate = self.delegate {
				delegate.thumbnailRightClicked(image: object, atLocation: event.locationInWindow)
			}
		}
		super.rightMouseDown(with: event)
	}
	
}
