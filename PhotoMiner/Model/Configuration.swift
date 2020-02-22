//
//  Configuration.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

/// Application configuratio singleton
class Configuration: NSObject {

	/// Shared object
	static let shared = Configuration()

	/// Ignore images smaller than this size
	let ignoreImagesBelowSize = 51200              // 50kB (50 * 1024 = 51200)

	/// Minimum width of sidepanel
	let sidepanelMinWidth = 150

	/// Maximum width of sidepanel
	let sidePanelMaxWidth = 500

	/// Extension of exported scan file
	let saveDataExtension = "pms"

	/// Use date of image creation as thumbnail label
	@objc dynamic var creationDateAsLabel = true {
		didSet {
			#if DEBUG
				NSLog("creationDateAsLabel: \(creationDateAsLabel)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Ask for confirmation if old scan exists and new scan was requested
	@objc dynamic var newScanMustBeConfirmed = true {
		didSet {
			#if DEBUG
				NSLog("newScanMustBeConfirmed: \(newScanMustBeConfirmed)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Ask for confirmation before removing images
	@objc dynamic var removeMustBeConfirmed = true {
		didSet {
			#if DEBUG
				NSLog("removeMustBeConfirmed: \(removeMustBeConfirmed)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Remove also directory after removing an image if this was the last file in it
	@objc dynamic var removeAlsoEmptyDirectories = false {
		didSet {
			#if DEBUG
				NSLog("removeAlsoEmptyDirectories: \(removeAlsoEmptyDirectories)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Hightlight images which have no EXIF data
	@objc dynamic var highlightPicturesWithoutExif = false {
		didSet {
			#if DEBUG
				NSLog("highlightPicturesWithoutExif: \(highlightPicturesWithoutExif)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Collapse groups by clicking header (not just the arrow on the left side)
	@objc dynamic var collapseByClickingHeader = false {
		didSet {
			#if DEBUG
				NSLog("collapseByClickingHeader: \(collapseByClickingHeader)")
			#endif
			self.saveConfiguration()
		}
	}

	/// Search for images
	@objc dynamic var searchForImages = true {
		   didSet {
			   #if DEBUG
				   NSLog("searchForImages: \(searchForImages)")
			   #endif
			   self.saveConfiguration()
		   }
	   }

	/// Search for movie files
	@objc dynamic var searchForMovies = true {
		   didSet {
			   #if DEBUG
				   NSLog("searchForMovies: \(searchForMovies)")
			   #endif
			   self.saveConfiguration()
		   }
	   }

	/// Display warning if previous scan was parsed from a file (warning about needing to drag&drop the directories to the app)
	var displayWarningForParsedScans = true {
		didSet {
			self.saveConfiguration()
		}
	}

	/// Remove original image after it was exported
	@objc dynamic var removeOriginalAfterExportingImages = false {
		didSet {
			self.saveConfiguration()
		}
	}

	// Flag indication if collapsing section is available on this system (available only from 10.12)
	@objc dynamic var isSectionCollapseAvailable:Bool {
		get {
			if #available(OSX 10.12, *) {
				return true
			}
			return false
		}
	}

	// Constructor loading configuration saved in user defaults
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
		if let boolValue = userDefaults.value(forKey: "removeOriginalAfterExportingImages") as? Bool {
			removeOriginalAfterExportingImages = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "searchForImages") as? Bool {
			searchForImages = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "searchForMovies") as? Bool {
			searchForMovies = boolValue
		}
	}

	// Save configuration to user defaults
	func saveConfiguration() {
		UserDefaults.standard.set(creationDateAsLabel, forKey: "creationDateAsLabel")
		UserDefaults.standard.set(newScanMustBeConfirmed, forKey: "newScanMustBeConfirmed")
		UserDefaults.standard.set(removeMustBeConfirmed, forKey: "removeMustBeConfirmed")
		UserDefaults.standard.set(removeAlsoEmptyDirectories, forKey: "removeAlsoEmptyDirectories")
		UserDefaults.standard.set(highlightPicturesWithoutExif, forKey: "highlightPicturesWithoutExif")
		UserDefaults.standard.set(collapseByClickingHeader, forKey: "collapseByClickingHeader")
		UserDefaults.standard.set(displayWarningForParsedScans, forKey: "displayWarningForParsedScans")
		UserDefaults.standard.set(removeOriginalAfterExportingImages, forKey: "removeOriginalAfterExportingImages")
		UserDefaults.standard.set(searchForImages, forKey: "searchForImages")
		UserDefaults.standard.set(searchForMovies, forKey: "searchForMovies")
		UserDefaults.standard.synchronize()
	}

}
