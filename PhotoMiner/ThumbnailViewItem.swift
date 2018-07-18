//
//  ThumbnailViewItem.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol ThumbnailViewItemDelegate {
	func thumbnailClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent)
	func thumbnailRightClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent)
}

class ThumbnailViewItem: NSCollectionViewItem {
	
	var delegate:ThumbnailViewItemDelegate? = nil
	
	private static let dragStartsAtDistance:CGFloat = 5.0
	
	override var isSelected:Bool {
		didSet {
			updateBackground()
		}
	}
	
	override var highlightState: NSCollectionViewItem.HighlightState {
		didSet {
			updateBackground()
		}
	}
	
	private(set) var hasBorder = false {
		didSet {
			updateBackground()
		}
	}
	
	override var representedObject:Any? {
		didSet {
			if let object = representedObject as? ImageData {
				object.setThumbnail()
				hasBorder = Configuration.shared.highlightPicturesWithoutExif ? !object.hasExif : false
				
				self.textField?.stringValue = object.imageName
				if Configuration.shared.creationDateAsLabel {
					let formatter = DateFormatter()
					formatter.dateStyle = .medium
					formatter.timeStyle = .short
					self.textField?.stringValue = formatter.string(from: object.creationDate)
				}
				self.imageView?.bind(NSBindingName(rawValue: "value"), to: object, withKeyPath: "imageThumbnail", options: nil)
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		view.wantsLayer = true
		view.layer?.backgroundColor = Colors.shared.thumbnail.frameColor.cgColor
		view.layer?.cornerRadius = 4.0
		
		// We re-set the representedObject for the case it was set before this function call
		let object = self.representedObject
		self.representedObject = object
		
		updateBackground()
    }
	
	func updateBackground() {
		if isSelected || (highlightState == .forSelection){
			if #available(OSX 10.13, *) {
				view.layer?.backgroundColor = NSColor(named: NSColor.Name("FrameColorSelected"))?.cgColor
			}
			if view.layer?.backgroundColor == nil {
				view.layer?.backgroundColor = Colors.shared.thumbnail.frameColorSelected.cgColor
			}
			view.layer?.borderColor = Colors.shared.thumbnail.borderColorSelected.cgColor
			if let textField = textField {
				textField.textColor = Colors.shared.thumbnail.textColorSelected
			}
		}
		else {
			if #available(OSX 10.13, *) {
				view.layer?.backgroundColor = NSColor(named: NSColor.Name("FrameColor"))?.cgColor
			}
			if view.layer?.backgroundColor == nil {
				view.layer?.backgroundColor = Colors.shared.thumbnail.frameColor.cgColor
			}
			view.layer?.borderColor = Colors.shared.thumbnail.borderColor.cgColor
			if let textField = textField {
				textField.textColor = Colors.shared.thumbnail.textColor
			}
		}
		view.layer?.borderWidth = hasBorder ? 2.0 : 0.0
	}
	
	// MARK: - Mouse events
	//
	
	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)
		self.delegate?.thumbnailClicked(self, with: event)
	}
	
	override func rightMouseDown(with event: NSEvent) {
		super.rightMouseDown(with: event)
		self.delegate?.thumbnailRightClicked(self, with: event)
	}
	
}
