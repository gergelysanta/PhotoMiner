//
//  TitlebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol TitlebarDelegate {
	func titlebar(_ controller: TitlebarController, startScanForPath scanPath: String?)
	func titlebar(_ controller: TitlebarController, cancelButtonPressed sender: NSButton)
	func titlebarSidebarToggled(_ controller: TitlebarController)
}

class TitlebarController: NSViewController {
	
	static let sidebarOnNotification  = Notification.Name("TitlebarSidebarOn")
	static let sidebarOffNotification = Notification.Name("TitlebarSidebarOff")
	
	var delegate:TitlebarDelegate?
	
	@IBOutlet private var titleField: NSTextField!
	@IBOutlet private var cancelButton: NSButton!
	@IBOutlet private var sidebarButton: NSButton!
	@IBOutlet private var progressIndicator: NSProgressIndicator!
	@IBOutlet private var scanButton: LongPressButton!

	private let sidebarOnImage  = NSImage(named: "SidebarOn")
	private let sidebarOffImage = NSImage(named: "SidebarOff")

//	private var longScanPressTimer: Repeater?
	private var longScanPressMenu = NSMenu()

	private var predefinedDirectories: [[String]] = [
		[NSLocalizedString("Scan Messages attachments", comment: "Scan Messages attachments"), "~/Library/Messages"],
		[NSLocalizedString("Scan Mail attachments", comment: "Scan Mail attachments"), "~/Library/Mail"]
	]

	override func viewDidLoad() {
		super.viewDidLoad()
		self.setTotalCount(0)
		self.progressOn(false)

		// Construct menu for scanButton longpress
		for (index, itemDef) in predefinedDirectories.enumerated() {
			let menuItem = NSMenuItem(title: itemDef[0], action: #selector(scanMenuItemSelected(_:)), keyEquivalent: "")
			menuItem.target = self
			menuItem.tag = index
			longScanPressMenu.addItem(menuItem)
		}

		scanButton.longPressMenu = longScanPressMenu

		NotificationCenter.default.addObserver(self, selector: #selector(sidebarOnNotification(notification:)),  name: TitlebarController.sidebarOnNotification,  object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sidebarOffNotification(notification:)), name: TitlebarController.sidebarOffNotification, object: nil)
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
		delegate?.titlebar(self, startScanForPath: nil)
	}

	@objc func scanMenuItemSelected(_ sender: NSMenuItem) {
		guard (0..<predefinedDirectories.count).contains(sender.tag) else { return }

		// Construct home directory
		// Sandboxed app will have home dir in it's sandboxed container, we need the user's home directory globally
		var homeDirectory = ""
		for component in NSHomeDirectory().components(separatedBy: "/") {
			if component.isEmpty { continue }
			homeDirectory += "/\(component)"
			if component == NSUserName() {
				break
			}
		}

		// Replace tilde in path
		let scanDirectory = predefinedDirectories[sender.tag][1].replacingOccurrences(of: "~", with: homeDirectory)

		// Start scan for this directory
		delegate?.titlebar(self, startScanForPath: scanDirectory)
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
		self.performSegue(withIdentifier: "settingsSegue", sender: self)
	}
	
}

//extension TitlebarController: NSMenuDelegate {
//
//	func menuDidClose(_ menu: NSMenu) {
////		scanButton.highlight(false)
////		NSApp.sendEvent(NSEvent(eventRef: <#T##UnsafeRawPointer#>))
//	}
//
//}
