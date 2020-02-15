//
//  LongPressButton.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 15/02/2020.
//  Copyright © 2020 TriKatz. All rights reserved.
//

import Cocoa

/// Button capable of displaying menu with additional actions when long-pressed
class LongPressButton: NSButton {

	/// Menu to be displayed when button pressed long
	var longPressMenu: NSMenu? {
		willSet {
			// Remove delegate of old menu (if exists)
			longPressMenu?.delegate = nil
		}
		didSet {
			// Set delegate of new menu (if set)
			longPressMenu?.delegate = self
		}
	}

	/// Flag indicating whether button whould execute it's action (shortClick) or was displaying a menu (longClick)
	private var shortClick: Bool = false

	override func mouseDown(with event: NSEvent) {
		// IMPORTANT: Don't call super.mouseDown here, we're reimplementing mouse press in this method

		// Highlight button
		self.isHighlighted = true

		// We assume, this will be a shortclick, default action should be executed instead of menu command
		shortClick = true

		// Start a timer displaying long-press menu
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			if self.shortClick,                // If this is an unfinished click
			   let menu = self.longPressMenu   // and menu is set
			{
				// Menu command will be executed (externally) instead of default action
				self.shortClick = false
				// Display the menu
				menu.popUp(positioning: nil, at: NSPoint(x: 0, y: self.frame.size.height + 5.0), in: self)
			}
		}
	}

	override func mouseUp(with event: NSEvent) {
		// IMPORTANT: Don't call super.mouseUp here, we're reimplementing mouse press in this method

		// Reset the state
		let wasShortClick = shortClick
		shortClick = false

		// Remove button highlight
		self.isHighlighted = false

		// Execute singleclick if press was not long
		if wasShortClick,                                // This was a shortclick
		   let action = self.action,                     // Button action is set
		   let target = self.target                      // Button target for action is set
		{
			// Send button's configured action
			NSApp.sendAction(action, to: target, from: self)
		}
	}

}

extension LongPressButton: NSMenuDelegate {

	func menuDidClose(_ menu: NSMenu) {
		// Menu closed: remove button highlight...
		self.isHighlighted = false
	}

}
