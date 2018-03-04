//
//  Configuration.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class Configuration: NSObject {
	
	static let shared = Configuration()
	
	let ignoreImagesBelowSize = 51200		// 50kB (50 * 1024 = 51200)
	let sidepanelMinSize = 150
	let sidePanelMaxSize = 500
	let saveDataExtension = "pms"

	@objc dynamic var creationDateAsLabel = true {
		didSet {
			#if DEBUG
				NSLog("creationDateAsLabel: \(creationDateAsLabel)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var newScanMustBeConfirmed = true {
		didSet {
			#if DEBUG
				NSLog("newScanMustBeConfirmed: \(newScanMustBeConfirmed)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var removeMustBeConfirmed = true {
		didSet {
			#if DEBUG
				NSLog("removeMustBeConfirmed: \(removeMustBeConfirmed)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var removeAlsoEmptyDirectories = false {
		didSet {
			#if DEBUG
				NSLog("removeAlsoEmptyDirectories: \(removeAlsoEmptyDirectories)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var highlightPicturesWithoutExif = false {
		didSet {
			#if DEBUG
				NSLog("highlightPicturesWithoutExif: \(highlightPicturesWithoutExif)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var collapseByClickingHeader = false {
		didSet {
			#if DEBUG
				NSLog("collapseByClickingHeader: \(collapseByClickingHeader)")
			#endif
			self.saveConfiguration()
		}
	}
	
	var displayWarningForParsedScans = true {
		didSet {
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var isSectionCollapseAvailable:Bool {
		get {
			if #available(OSX 10.12, *) {
				return true
			}
			return false
		}
	}
	
	private override init() {
		super.init()
		// Load configuration
		let userDefaults = UserDefaults.standard
		if let boolValue = userDefaults.value(forKey: "creationDateAsLabel") as? Bool {
			creationDateAsLabel = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "newScanMustBeConfirmed") as? Bool {
			newScanMustBeConfirmed = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "removeMustBeConfirmed") as? Bool {
			removeMustBeConfirmed = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "removeAlsoEmptyDirectories") as? Bool {
			removeAlsoEmptyDirectories = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "highlightPicturesWithoutExif") as? Bool {
			highlightPicturesWithoutExif = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "collapseByClickingHeader") as? Bool {
			collapseByClickingHeader = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "displayWarningForParsedScans") as? Bool {
			displayWarningForParsedScans = boolValue
		}
	}
	
	func saveConfiguration() {
		UserDefaults.standard.set(creationDateAsLabel, forKey: "creationDateAsLabel")
		UserDefaults.standard.set(newScanMustBeConfirmed, forKey: "newScanMustBeConfirmed")
		UserDefaults.standard.set(removeMustBeConfirmed, forKey: "removeMustBeConfirmed")
		UserDefaults.standard.set(removeAlsoEmptyDirectories, forKey: "removeAlsoEmptyDirectories")
		UserDefaults.standard.set(highlightPicturesWithoutExif, forKey: "highlightPicturesWithoutExif")
		UserDefaults.standard.set(collapseByClickingHeader, forKey: "collapseByClickingHeader")
		UserDefaults.standard.set(displayWarningForParsedScans, forKey: "displayWarningForParsedScans")
		UserDefaults.standard.synchronize()
	}
	
}
