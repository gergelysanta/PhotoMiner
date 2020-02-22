//
//  ShadeView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 22/02/2020.
//  Copyright © 2020 TriKatz. All rights reserved.
//

import Cocoa

class ShadeView: NSView {

	override func draw(_ dirtyRect: NSRect) {
		if #available(OSX 10.13, *) {
			NSColor(named: "DropAreaShadeColor")?.setFill()
		} else {
			NSColor(calibratedWhite: 1.0, alpha: 0.9).setFill()
		}
		dirtyRect.fill()
		super.draw(dirtyRect)
	}

	func show() {
		self.animator().alphaValue = 1.0
	}

	func hide() {
		self.animator().alphaValue = 0.0
	}

}
