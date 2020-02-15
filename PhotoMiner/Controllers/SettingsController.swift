//
//  SettingsController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 14/04/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class SettingsController: NSViewController {
	
	@objc dynamic let configuration = Configuration.shared
	
	override func dismiss(_ sender: Any?) {
		super.dismiss(sender)
		if let appDelegate = NSApp.delegate as? AppDelegate {
			appDelegate.mainWindowController?.refreshPhotos()
		}
	}
	
}
