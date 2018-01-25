//
//  TitlebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol TitlebarDelegate {
	func titlebar(_ controller: TitlebarController, scanButtonPressed sender: NSButton)
	func titlebar(_ controller: TitlebarController, cancelButtonPressed sender: NSButton)
	func titlebarSidebarToggled(_ controller: TitlebarController)
}

class TitlebarController: NSViewController {
	
	static let sidebarOnNotification  = Notification.Name("TitlebarSidebarOn")
	static let sidebarOffNotification = Notification.Name("TitlebarSidebarOff")
	
	var delegate:TitlebarDelegate?
	
	@IBOutlet private weak var titleField: NSTextField!
	@IBOutlet private weak var cancelButton: NSButton!
	@IBOutlet private weak var sidebarButton: NSButton!
	@IBOutlet private weak var progressIndicator: NSProgressIndicator!
	
	private let sidebarOnImage  = NSImage(named: NSImage.Name("SidebarOn"))
	private let sidebarOffImage = NSImage(named: NSImage.Name("SidebarOff"))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.setTotalCount(0)
		self.progressOn(false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.sidebarOnNotification(notification:)),  name: TitlebarController.sidebarOnNotification,  object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.sidebarOffNotification(notification:)), name: TitlebarController.sidebarOffNotification, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func sidebarOnNotification(notification: Notification){
		sidebarButton.image = sidebarOnImage
	}
	
	@objc func sidebarOffNotification(notification: Notification){
		sidebarButton.image = sidebarOffImage
	}
	
	@IBAction func scanButtonPressed(_ sender: NSButton) {
		delegate?.titlebar(self, scanButtonPressed: sender)
	}
	
	@IBAction func cancelButtonPressed(_ sender: NSButton) {
		delegate?.titlebar(self, cancelButtonPressed: sender)
	}
	
	@IBAction func sidebarButtonPressed(_ sender: NSButton) {
		delegate?.titlebarSidebarToggled(self)
	}
	
	func progressOn(_ progress: Bool) {
		if progress {
			progressIndicator.startAnimation(self)
			progressIndicator.isHidden = false
			cancelButton.isHidden = false
		}
		else {
			progressIndicator.stopAnimation(self)
			progressIndicator.isHidden = true
			cancelButton.isHidden = true
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
