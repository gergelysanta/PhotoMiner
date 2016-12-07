//
//  TitlebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol TitlebarDelegate {
	func setupButtonPressed(_ sender: NSButton)
	func scanButtonPressed(_ sender: NSButton)
}

class TitlebarController: NSViewController {
	
	var delegate:TitlebarDelegate?
	
	@IBAction func scanButtonPressed(_ sender: NSButton) {
		if let delegate = self.delegate {
			delegate.scanButtonPressed(sender);
		}
	}
	
	@IBAction func setupButtonPressed(_ sender: NSButton) {
		if let delegate = self.delegate {
			delegate.setupButtonPressed(sender);
		}
	}
	
}
