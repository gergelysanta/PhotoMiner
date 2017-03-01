//
//  HeaderView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 01/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class HeaderView: NSView {
	
	@IBOutlet weak var sectionTitle: NSTextField!
	@IBOutlet weak var sectionInfo: NSTextField!
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
		// Fill view with a top-down gradient
		let gradient = NSGradient(starting: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
		                          ending: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 0.8))
		gradient?.draw(in: self.bounds, angle: -90.0)
	}
	
}
