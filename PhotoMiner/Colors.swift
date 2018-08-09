//
//  Colors.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 02/07/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

struct Colors {
	
	struct Thumbnail{
		static var frameColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("FrameColor")) {
						return color
					}
				}
				return NSColor(red:0.27, green:0.65, blue:0.88, alpha:1.00)
			}
		}
		
		static var frameColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("FrameColorSelected")) {
						return color
					}
				}
				return NSColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
			}
		}
		
		static var borderColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("BorderColor")) {
						return color
					}
				}
				return NSColor(red:0.25, green:0.58, blue:0.78, alpha:1.00)
			}
		}
		
		static var borderColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("BorderColorSelected")) {
						return color
					}
				}
				return NSColor(red:1.00, green:0.85, blue:0.88, alpha:1.00)
			}
		}
		
		static var textColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("TextColor")) {
						return color
					}
				}
				return NSColor.white
			}
		}
		
		static var textColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: NSColor.Name("TextColorSelected")) {
						return color
					}
				}
				return NSColor.darkGray
			}
		}
	}
	
	// Disable constructor (make private)
	private init() {
	}
	
}
