//
//  TitlebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol TitlebarDelegate {
	func buttonPressed(_ sender: NSButton)
}

class TitlebarController: NSViewController {
	
	var delegate:TitlebarDelegate?
	
	@IBOutlet weak var titlebarProgressIndicator: NSProgressIndicator!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.progressOn(false)
	}
	
	@IBAction func buttonPressed(_ sender: NSButton) {
		if let delegate = self.delegate {
			delegate.buttonPressed(sender);
		}
	}
	
	func progressOn(_ progress: Bool) {
		if progress {
			titlebarProgressIndicator.startAnimation(self)
			titlebarProgressIndicator.isHidden = false
		}
		else {
			titlebarProgressIndicator.stopAnimation(self)
			titlebarProgressIndicator.isHidden = true
		}
	}
	
}
