//
//  Colors.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 02/07/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class Colors: NSObject {

	static let shared = Colors()
	
	struct Thumbnail{
		private(set) var frameColor:NSColor
		private(set) var frameColorSelected:NSColor
		private(set) var borderColor:NSColor
		private(set) var borderColorSelected:NSColor
		private(set) var textColor:NSColor
		private(set) var textColorSelected:NSColor
		
		init() {
			frameColor = NSColor(red:0.27, green:0.65, blue:0.88, alpha:1.00)
			frameColorSelected = NSColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
			borderColor = NSColor(red:0.25, green:0.58, blue:0.78, alpha:1.00)
			borderColorSelected = NSColor(red:1.00, green:0.85, blue:0.88, alpha:1.00)
			textColor = NSColor.white
			textColorSelected = NSColor.darkGray
			
			if #available(OSX 10.13, *) {
				if let color = NSColor(named: NSColor.Name("FrameColor")) {
					frameColor = color
				}
				if let color = NSColor(named: NSColor.Name("FrameColorSelected")) {
					frameColorSelected = color
				}
				if let color = NSColor(named: NSColor.Name("BorderColor")) {
					borderColor = color
				}
				if let color = NSColor(named: NSColor.Name("BorderColorSelected")) {
					borderColorSelected = color
				}
				if let color = NSColor(named: NSColor.Name("TextColor")) {
					textColor = color
				}
				if let color = NSColor(named: NSColor.Name("TextColorSelected")) {
					textColorSelected = color
				}
			}
		}
	}
	
	let thumbnail = Thumbnail()
	
	private override init() {
		super.init()
	}
	
}
