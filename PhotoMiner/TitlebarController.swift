//
//  TitlebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol TitlebarDelegate {
	func scanButtonPressed(_ sender: NSButton)
}

class TitlebarController: NSViewController {
	
	var delegate:TitlebarDelegate?
	
	@IBOutlet private weak var titleField: NSTextField!
	@IBOutlet private weak var progressIndicator: NSProgressIndicator!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.setTotalCount(0)
		self.progressOn(false)
	}
	
	@IBAction func scanButtonPressed(_ sender: NSButton) {
		if let delegate = self.delegate {
			delegate.scanButtonPressed(sender);
		}
	}
	
	func progressOn(_ progress: Bool) {
		if progress {
			progressIndicator.startAnimation(self)
			progressIndicator.isHidden = false
		}
		else {
			progressIndicator.stopAnimation(self)
			progressIndicator.isHidden = true
		}
	}
	
	func setTotalCount(_ totalCount: Int) {
		titleField.stringValue = "PhotoMiner"
		if totalCount > 0 {
			let countLabel = (totalCount > 1)
				? NSLocalizedString("pictures", comment: "Picture count: >1 pictures")
				: NSLocalizedString("picture", comment: "Picture count: 1 picture")
			
			titleField.stringValue = String(format: "%@ (%d %@)", titleField.stringValue, totalCount, countLabel)
		}
	}
	
	func showSettings() {
		self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "settingsSegue"), sender: self)
	}
	
}
