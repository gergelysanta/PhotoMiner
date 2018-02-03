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
	
	private(set) var lookupFolders = [String]()
	let ignoreImagesBelowSize = 51200		// 50kB (50 * 1024 = 51200)
	
	private var scannedDirectories:Set<String> = []
	
	let sidepanelMinSize = 150
	let sidePanelMaxSize = 500
	
	var openedFileUrl:URL?
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
	}
	
	@discardableResult func setLookupDirectories(_ pathList: [String]) -> Bool {
		var newLookupFolders = [String]()
		var isDirectory:ObjCBool = false
		var haveValidPath  = false
		for path in pathList {
			if FileManager.default.fileExists(atPath: path, isDirectory:&isDirectory) {
				if isDirectory.boolValue {
					// Path exists and is a directory -> add to lookupFolders list
					#if DEBUG
					NSLog("Add lookup folder: \(path)")
					#endif
					haveValidPath = true
					newLookupFolders.append(path)
				}
			}
		}
		if haveValidPath {
			lookupFolders = newLookupFolders
			openedFileUrl = nil
		}
		return haveValidPath
	}
	
	func addScannedDirectories(_ directories: [String]) {
		scannedDirectories = scannedDirectories.union(directories)
	}
	
	func wasDirectoryScanned(_ directory: String) -> Bool {
		return scannedDirectories.contains(directory)
	}
	
	func saveConfiguration() {
		UserDefaults.standard.set(creationDateAsLabel, forKey: "creationDateAsLabel")
		UserDefaults.standard.set(newScanMustBeConfirmed, forKey: "newScanMustBeConfirmed")
		UserDefaults.standard.set(removeMustBeConfirmed, forKey: "removeMustBeConfirmed")
		UserDefaults.standard.set(removeAlsoEmptyDirectories, forKey: "removeAlsoEmptyDirectories")
		UserDefaults.standard.set(highlightPicturesWithoutExif, forKey: "highlightPicturesWithoutExif")
		UserDefaults.standard.synchronize()
	}
	
}
