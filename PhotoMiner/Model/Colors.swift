//
//  Colors.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 02/07/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

/// Colors used by application
struct Colors {

	/// Colors of thumbnails
	struct Thumbnail{

		/// Color of the thumbnail frame
		static var frameColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "FrameColor") {
						return color
					}
				}
				return NSColor(red:0.27, green:0.65, blue:0.88, alpha:1.00)
			}
		}

		/// Color of the thumbnail frame when selected
		static var frameColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "FrameColorSelected") {
						return color
					}
				}
				return NSColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
			}
		}

		/// Color of the thumbnail frame border
		static var borderColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "BorderColor") {
						return color
					}
				}
				return NSColor(red:0.25, green:0.58, blue:0.78, alpha:1.00)
			}
		}

		/// Color of the thumbnail frame border when selected
		static var borderColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "BorderColorSelected") {
						return color
					}
				}
				return NSColor(red:1.00, green:0.85, blue:0.88, alpha:1.00)
			}
		}

		/// Color of the thumbnail text
		static var textColor:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "TextColor") {
						return color
					}
				}
				return NSColor.white
			}
		}

		/// Color of the thumbnail text when selected
		static var textColorSelected:NSColor {
			get {
				if #available(OSX 10.13, *) {
					if let color = NSColor(named: "TextColorSelected") {
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
