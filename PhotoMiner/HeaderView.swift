//
//  HeaderView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 01/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol HeaderViewDelegate {
	func headerToggleCollapse(_ headerView: HeaderView)
}

class HeaderView: NSView {
	
	@IBOutlet private weak var sectionTitle: NSTextField!
	@IBOutlet private weak var sectionInfo: NSTextField!
	
	// Don't make reference of toggleCollapseButton 'weak'
	// This button will be removed on systems where collapsing is not supported (10.11-)
	// For that case it must be strongly referenced
	// weak reference will be released after removing from superview and this will result invalid reference later (and crash)
	@IBOutlet var toggleCollapseButton: NSButton!
	
	var headerDelegate:HeaderViewDelegate?
	
	private(set) var isCollapsed = false {
		didSet {
			if isCollapsed {
				toggleCollapseButton.image = NSImage(named: NSImage.Name("NSTouchBarGoForwardTemplate"))
			}
			else {
				toggleCollapseButton.image = NSImage(named: NSImage.Name("NSTouchBarGoDownTemplate"))
			}
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
		// Fill view with a top-down gradient
		let gradient = NSGradient(starting: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
		                          ending: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 0.8))
		gradient?.draw(in: self.bounds, angle: -90.0)
	}
	
	func setTitle(date: Date) {
		let formatter = DateFormatter()
		formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMyyyy", options: 0, locale: nil)
		self.sectionTitle.stringValue = formatter.string(from: date)
	}
	
	func setTitle(year: Int, andMonth month: Int) {
		let calendar = Calendar.current
		var dateComponents = calendar.dateComponents([.year, .month], from: Date())
		dateComponents.year = year
		dateComponents.month = month
		
		if let headerDate = calendar.date(from: dateComponents) {
			self.setTitle(date: headerDate)
		}
		else {
			self.sectionTitle.stringValue = String(format: "%lu %02lu", year, month)
		}
	}
	
	func setPictureCount(_ count: Int) {
		if count < 0 {
			sectionInfo.stringValue = ""
		}
		else {
			let countLabel = (count > 1)
					? NSLocalizedString("pictures", comment: "Picture count: >1 pictures")
					: NSLocalizedString("picture", comment: "Picture count: 1 picture")
			sectionInfo.stringValue = String(format: "%d %@", count, countLabel)
		}
	}
	
	private func toggleCollapse() {
		if let delegate = self.headerDelegate,
			Configuration.shared.isSectionCollapseAvailable
		{
			delegate.headerToggleCollapse(self)
			isCollapsed = !isCollapsed
		}
	}
	
	@IBAction func toggleCollapseButtonClicked(_ sender: NSButton) {
		self.toggleCollapse()
	}
	
	override func mouseUp(with event: NSEvent) {
		if Configuration.shared.collapseByClickingHeader {
			self.toggleCollapse()
		}
	}
	
}
